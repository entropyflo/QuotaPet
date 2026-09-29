# Manual acceptance checklist

- [ ] Live account: with Codex signed in, launch QuotaPet and confirm its five-hour percentage/reset agree with the account quota; verify no fake 100% appears when the window is absent.
- [ ] Dragging: unlock position, drag by the transparent pet window, quit/relaunch, and confirm the position is restored.
- [ ] Size modes: hover and switch between 0.5x and 1x, repeat from the menu, then relaunch and confirm the selected size is restored.
- [ ] Apple states: verify the 0.5x circular quota ring and full-size text remain readable directly over every green-to-brown 2D apple stage; verify the 1x sprite advances through all ten cells without bleeding from adjacent cells.
- [ ] Glass optics: on macOS 26 or later, drag the pet across a light window, dark window, colorful image, and the desktop. Confirm the clear glass transmits and responds to underlying content and pointer movement while text stays legible. Repeat with Reduce Transparency enabled and confirm the accessible opaque fallback.
- [ ] Weekly hover: in 1x mode on macOS 26 or later, move the pointer in and out and confirm a small glass circle emerges from the bottom center of the five-hour surface, grows and separates into the complete weekly panel. On pointer exit the panel must shrink back to the same circle and be visibly absorbed at that exact point. The complete motion should be quick but perceptible. Verify the material/scale fallback on macOS 14–15 and repeat with Reduce Motion enabled.
- [ ] Lock: lock position and confirm background dragging no longer moves the panel.
- [ ] Click-through: enable it and confirm clicks reach the app beneath; use the menu bar to disable it again.
- [ ] Always on top: toggle the option and verify window level changes without stealing keyboard focus.
- [ ] Multiple displays: move to each display, disconnect the saved display, relaunch, and confirm the pet returns to a visible screen.
- [ ] Spaces/full screen: verify the pet appears across Spaces and alongside a full-screen app.
- [ ] Appearance/accessibility: check light/dark mode and Reduce Motion.
- [ ] Sleep/wake: sleep past or near a quota change, wake, and confirm a refresh occurs.
- [ ] Stale data: interrupt the Codex child and confirm the last successful value remains visible as stale while bounded reconnect runs.
- [ ] Preview: run 95%, 20%, 0%, and offline preview states and inspect green/normal, red/tired, sleeping, and gray/offline rendering.
- [ ] Login item: enable/disable it and verify macOS System Settings reflects the choice.
- [ ] Quit cleanup: choose Quit, then confirm no child started by QuotaPet remains (for example with `pgrep -af 'codex app-server'`, accounting for unrelated Codex processes).
