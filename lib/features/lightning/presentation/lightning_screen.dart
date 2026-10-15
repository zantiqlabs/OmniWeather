import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/providers/location_provider.dart';
import '../../../shared/widgets/location_search_delegate.dart';

/// Shows a full-screen embed of lightningmaps.org (powered by Blitzortung)
/// centred on the active location.
///
/// The WebView approach avoids the rate-limiting/IP-ban risk of opening
/// hundreds of direct WebSocket connections from mobile clients, while still
/// showing the same real-time data that Blitzortung streams to its web viewer.
///
/// Location changes (via search or GPS) reload the URL with updated coordinates
/// so the map pans to the correct area automatically.
class LightningScreen extends ConsumerStatefulWidget {
  const LightningScreen({super.key});

  @override
  ConsumerState<LightningScreen> createState() => _LightningScreenState();
}

class _LightningScreenState extends ConsumerState<LightningScreen> {
  late final WebViewController _webController;
  bool _isLoading = true;

  static const _defaultLat  = 51.5;
  static const _defaultLon  = -0.1;
  static const _defaultZoom = 7;

  /// JavaScript injected after every page load.
  ///
  /// Removes <iframe> and <ins> elements (used exclusively by ad networks on
  /// this page — the Leaflet map uses <canvas>/<img>/<div> only) and attaches
  /// a MutationObserver so ads that load asynchronously are caught too.
  static const _adKillerJs = r'''
(function () {
  var mapSelector = '.leaflet-container, #map, #lmap';

  // ── CSS ──────────────────────────────────────────────────────────────────
  var style = document.createElement('style');
  style.textContent = [
    'html, body {',
    '  background: #0D1B2A !important;',
    '  margin: 0 !important; padding: 0 !important;',
    '  width: 100% !important; height: 100% !important;',
    '  overflow: hidden !important;',
    '}',
    // NOTE: position:fixed can be broken by a CSS transform on an ancestor,
    // which is why we also do the JS re-parent below as a fallback.
    '#lmap, #map, .leaflet-container {',
    '  position: fixed !important;',
    '  inset: 0 !important;',
    '  width: 100% !important; height: 100% !important;',
    '  max-width: none !important; max-height: none !important;',
    '  margin: 0 !important; padding: 0 !important;',
    '  box-sizing: border-box !important;',
    '  z-index: 10000 !important;',
    '}',
    /* Promote the map CONTAINER to a compositor layer for smoother panning.
       Do NOT apply transform overrides to .leaflet-tile or .leaflet-tile-container
       — Leaflet uses translate() on those to position tiles; overriding with
       !important breaks the layout (everything ends up at 0,0). */
    '.leaflet-container {',
    '  -webkit-backface-visibility: hidden !important;',
    '  backface-visibility: hidden !important;',
    '}',
    /* Remove Leaflet tile fade — tiles appear instantly rather than fading in,
       which eliminates the cross-fade flicker during fast panning. */
    '.leaflet-fade-anim .leaflet-tile,',
    '.leaflet-zoom-anim .leaflet-zoom-animated {',
    '  transition: none !important;',
    '}',
  ].join('\n');
  document.head.appendChild(style);

  function killAds() {
    // Remove ad leaf elements.
    document.querySelectorAll('iframe, ins').forEach(function (el) {
      el.remove();
    });

    // Remove ad wrappers — guard both directions so we never nuke the map.
    document.querySelectorAll('[id*="ad"],[class*="ad"],[id*="banner"],[class*="banner"]')
      .forEach(function (el) {
        if (el.closest(mapSelector) || el.querySelector(mapSelector)) return;
        el.remove();
      });

    // Hide ALL direct body children that don't contain or ARE the map.
    // Using * (not just div) catches section/aside/header/footer wrappers too.
    document.querySelectorAll('body > *').forEach(function (el) {
      if (el.tagName === 'SCRIPT' || el.tagName === 'STYLE' || el.tagName === 'NOSCRIPT') return;
      if (el.querySelector(mapSelector) || el.matches(mapSelector)) return;
      el.style.cssText = 'display:none!important';
    });

    // Darken any element whose computed background is still white.
    // This catches elements our selector missed (wrong id/class, inline style, etc.)
    document.querySelectorAll('body *').forEach(function (el) {
      if (el.closest(mapSelector) || el.querySelector(mapSelector)) return;
      var bg = window.getComputedStyle(el).backgroundColor;
      if (bg === 'rgb(255, 255, 255)' || bg === 'rgba(255, 255, 255, 1)') {
        el.style.setProperty('background-color', '#0D1B2A', 'important');
      }
    });
  }

  // If position:fixed is broken by a transform ancestor, re-parent the map
  // element directly under <body> so it is guaranteed to cover the viewport.
  function hoistMap() {
    var mapEl = document.querySelector(mapSelector);
    if (!mapEl || mapEl.parentElement === document.body) return;
    document.body.appendChild(mapEl);
    // Re-apply inline style so it definitely takes effect after reparenting.
    mapEl.style.cssText =
      'position:fixed!important;inset:0!important;' +
      'width:100%!important;height:100%!important;z-index:10000!important;';
  }

  killAds();
  hoistMap();

  // Tell Leaflet its container changed size so it redraws tiles edge-to-edge.
  requestAnimationFrame(function () {
    window.dispatchEvent(new Event('resize'));
  });

  new MutationObserver(function () {
    killAds();
    hoistMap();
  }).observe(document.body, { childList: true, subtree: true });
})();
''';

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Pretend to be a desktop Chrome so the site skips its mobile ad banner.
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Safari/537.36',
      )
      ..setBackgroundColor(const Color(0xFF0D1B2A))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (_) async {
          await _webController.runJavaScript(_adKillerJs);
          if (mounted) setState(() => _isLoading = false);
        },
      ));

    // Load once the widget tree is ready so we can read the active location.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = ref.read(locationProvider).activeLocation;
      _loadMap(
        lat: loc?.latitude  ?? _defaultLat,
        lon: loc?.longitude ?? _defaultLon,
      );
    });
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  /// Reloads the page centred on [lat]/[lon].
  ///
  /// lightningmaps.org reads its hash only on initial page load and does not
  /// respond to runtime hash changes, so a full loadRequest is required every
  /// time the location changes. The ad-killer + background fix scripts re-run
  /// automatically via onPageFinished.
  void _loadMap({required double lat, required double lon}) {
    // A timestamp query param makes every URL unique so Android WebView is
    // forced into a real page navigation instead of silently treating the
    // hash change as an in-page anchor scroll.
    final ts = DateTime.now().millisecondsSinceEpoch;
    final url = 'https://www.lightningmaps.org/?_=$ts'
        '#m=ocs;t=3;s=0;o=0;b=;ts=0;'
        'y=${lat.toStringAsFixed(4)};'
        'x=${lon.toStringAsFixed(4)};'
        'z=$_defaultZoom;d=2;dl=2;dc=0;';
    _webController.loadRequest(Uri.parse(url));
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _goToDeviceLocation() async {
    final loc =
        await ref.read(locationProvider.notifier).requestDeviceLocation();
    if (!mounted) return;
    // Always reload — if GPS didn't return a new fix, fall back to whatever
    // the provider already has.  This covers the case where the user scrolled
    // the WebView map (no app-level location change) and then taps the button:
    // without this the early-return on null would silently do nothing.
    final active = ref.read(locationProvider).activeLocation;
    _loadMap(
      lat: loc?.latitude  ?? active?.latitude  ?? _defaultLat,
      lon: loc?.longitude ?? active?.longitude ?? _defaultLon,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final location      = locationState.activeLocation;

    // Re-centre the map whenever the user picks a new location elsewhere
    // (e.g. from the search delegate or the forecast screen's carousel).
    ref.listen(locationProvider, (previous, next) {
      final loc = next.activeLocation;
      if (loc == null) return;
      final prevLoc = previous?.activeLocation;
      if (prevLoc?.latitude  == loc.latitude &&
          prevLoc?.longitude == loc.longitude) return;
      _loadMap(lat: loc.latitude, lon: loc.longitude);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(location != null ? '⚡ ${location.name}' : 'Lightning'),
        actions: [
          // Search location
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search location',
            onPressed: () => showSearch(
              context: context,
              delegate: LocationSearchDelegate(ref),
            ),
          ),
          // GPS — centre on device location
          IconButton(
            icon: locationState.isLocating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            tooltip: 'My location',
            onPressed: locationState.isLocating ? null : _goToDeviceLocation,
          ),
          // Reload — refreshes the live strike feed
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: () {
              final loc = ref.read(locationProvider).activeLocation;
              _loadMap(
                lat: loc?.latitude  ?? _defaultLat,
                lon: loc?.longitude ?? _defaultLon,
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _webController),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}