# AGENTS.md — Conduit Architecture & Hermes Integration

This document outlines the architecture, environment setup, and integration specifications for AI coding agents working on Conduit.

---

## 1. Hermes Agent Backend & Connection Architecture

Conduit integrates natively with Nous Research's **Hermes Agent** using the **Hermes Desktop Gateway API** (not classic Open WebUI mode).

- **Implementation**: Located primarily under `packages/conduit_core/lib/features/hermes/`.
  - Service: `HermesDesktopApiService` (`hermes_desktop_api_service.dart`)
  - Transport: `HermesDesktopRpcClient` (`hermes_desktop_transport.dart`)
  - Live & Turn Runtime: `hermes_desktop_live_runtime.dart`, `hermes_desktop_turn_runtime.dart`
  - Decision Storage: `HermesPendingDecisionStore` (`hermes_pending_decision_store.dart`)
  - UI Overlay: `HermesComposerPromptOverlay` (`lib/features/hermes/widgets/hermes_message_interactions.dart`)
- **Protocol**: JSON-RPC 2.0 bidirectional over WebSocket at `/api/ws` with auxiliary REST endpoints.
- **Wire Flow**:
  1. Client acquires a WS ticket via `POST /api/auth/ws-ticket` (or supplies Bearer / legacy token).
  2. Upgrades connection to WebSocket `wss://<host>:<port>/api/ws?ticket=<ticket>`.
  3. Server emits `gateway.ready` event upon successful connection handshake.
  4. Client advertises capabilities via `client.capabilities` with `{"server_requests": true}` (see Section 3).

---

## 2. Network Topology & Access via Tailscale

Conduit accesses Hermes remotely across devices using a private **Tailscale** overlay network.

- **Infrastructure**:
  - **Host**: VPS (`personal-vps`), running Tailscale daemon.
  - **Clients**: Mobile devices (e.g. Pixel 9 Pro), Mac workstations, and tablets running the Tailscale app.
- **Gateway Endpoint**:
  ```text
  https://ubuntu-4gb-fsn1-1.tail1fba48.ts.net:9119
  ```
  - Tailscale provides encrypted mesh routing and TLS certificates for MagicDNS (`*.tail1fba48.ts.net`).
  - Nginx on `personal-vps` proxies port `9119` to loopback `127.0.0.1:9119` (`hermes-dashboard.service`).
- **Authentication**:
  - Basic Auth / UI Login: `david`
  - Session Token / API Bearer Key: configured in Hermes `.env` / `config.yaml`.

---

## 3. Server-to-Client Requests (`server_requests`) Protocol

Hermes Agent supports interactive questions and confirmations initiated by the model or tools during execution turns.

### Supported Methods
- **`clarify`**: Interactive forms/questions (single or batch choices and text inputs).
- **`sudo`**: Privilege escalation / password prompt.
- **`secret`**: Secret input / token prompt.
- **`approval`**: Tool action execution authorization.
- **`request.cancel`**: Notification that a prompt timed out or was dismissed.

### Critical Implementation Rules
1. **Capability Advertisement (`client.capabilities`)**:
   - Must be called upon connection after `gateway.ready`.
   - **CRITICAL**: The payload MUST NOT include extra parameters like `profile` (`includeDefaultParams: false`). Hermes strictly validates `ClientCapabilitiesParams` with Pydantic and will return code `4000 (Extra inputs are not permitted)` if foreign fields are present, disabling all server-to-client requests.
2. **Direct JSON-RPC Response Frames**:
   - The server expects direct JSON-RPC 2.0 response frames (`{"jsonrpc": "2.0", "id": "<request_id>", "result": ...}`).
   - `clarify` result format: `{"answers": {<qid>: <answer>}, "outcome": "submitted"}`.
   - `sudo` / `secret` result format: `{"value": <value>}`.
   - `approval` result format: `{"choice": <choice>}`.
   - Canonical fallbacks (`request.answer`, `clarify.respond`) are invoked as secondary support.

---

## 4. Local Development & Toolchain Constraints

### Flutter & Dart Versioning
- **Constraint**: Conduit requires Flutter `>=3.47.0` (Dart `>=3.13.0`).
- **Isolation**: To prevent conflicts with other projects on the machine (e.g., `Azy-mobile` using Flutter 3.44.0 at `/Users/david/Documents/flutter`):
  - Conduit uses an isolated Flutter SDK installed at:
    ```text
    /Users/david/Documents/flutter_3.47
    ```
  - Workspace `.vscode/settings.json` is pinned to `"dart.flutterSdkPath": "/Users/david/Documents/flutter_3.47"`.

### Useful Commands
- **Run Application**:
  ```bash
  ~/Documents/flutter_3.47/bin/flutter run
  ```
- **Build Android APK (Debug)**:
  ```bash
  ~/Documents/flutter_3.47/bin/flutter build apk --debug
  ```
- **Build Android APK (Release for Pixel 9 Pro / arm64)**:
  ```bash
  ~/Documents/flutter_3.47/bin/flutter build apk --release --target-platform android-arm64
  ```
- **Code Generation (Drift, Freezed, Riverpod)**:
  ```bash
  ~/Documents/flutter_3.47/bin/dart run build_runner build --delete-conflicting-outputs
  ```
- **Run Hermes Core Tests**:
  ```bash
  cd packages/conduit_core && ~/Documents/flutter_3.47/bin/dart test test/features/hermes/hermes_desktop_transport_test.dart
  ```

---

## 5. Repository & Git Workflow

- **Origin**: `https://github.com/david-dkp/conduit.git` (Active development fork).
- **Upstream**: `https://github.com/cogwheel0/conduit.git` (Official upstream).
- **Default Branch**: `main`.
