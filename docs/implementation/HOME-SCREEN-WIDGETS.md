# Remorrow Today — Home Screen widgets
A small and medium iOS WidgetKit widget displays aggregate counts for upcoming, today and overdue items in the Figma-inspired blue/navy visual language. No private titles appear by default. A separate Settings opt-in allows showing the next item's title and due time on medium widgets.

The containing app publishes a Codable summary into the existing private App Group shared defaults and reloads timelines when saved items change. WidgetKit can show cached data and decides actual refresh timing. The extension never reads Messages, accesses the network, or queries the main app database. Widgets require signing and the App Group capability for **RemorrowWidget** plus the other three targets.

Test: pull main, regenerate `xcodegen generate`, run on device. Long-press Home Screen → Add Widget → Remorrow Today. Test count-only default, opt-in, and opt-out; verify uninstall, locked phone and app-group configuration. Simulator compile is not a physical widget acceptance test.
