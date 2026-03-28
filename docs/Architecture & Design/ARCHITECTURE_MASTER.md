# 👑 JoyMini Architecture Master Document v12.0

> **Purpose**: Unified architecture document consolidating all architecture-related content  
> **Version**: 12.0  
> **Last Updated**: 2026-03-28  
> **Replaces**: Top-Level Architecture Blueprint.md, PROJECT_ARCHITECTURE_SUMMARY.md

---

## 📋 Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [System Context & Boundaries](#2-system-context--boundaries)
3. [Core Layered Model](#3-core-layered-model)
4. [Technology Stack](#4-technology-stack)
5. [Directory Structure](#5-directory-structure)
6. [Architecture Decision Records](#6-architecture-decision-records)
7. [Architecture Rules](#7-architecture-rules)
8. [Related Documents](#8-related-documents)

---

## 1. Architecture Overview

JoyMini is not a typical display app, but an industrial-grade cross-platform foundation that deeply integrates **"Instant Messaging (IM)"**, **"High-Concurrency Group Buying (Social E-commerce)"**, and **"Financial-Grade Wallet (Wallet)"**.

The core vision of this architecture design is:

* **Platform Parity**: One codebase perfectly supports iOS, Android, and Web (WASM) execution, with physical isolation of underlying differences.
* **State Determinism**: Physically eliminates state desynchronization, multi-account data leakage, and financial calculation precision loss.
* **Millisecond UX**: Through SWR architecture, viewport preloading, and local repaint isolation, maintains 60 FPS even with massive lists and high-frequency communication.

### Project Core Features

Based on comprehensive analysis of `pubspec.yaml`, routing files (`app_router.dart`), and page directory structure, the main feature modules include:

- **E-commerce Shopping System**: Product display, categories, details, group buying, flash sales, order management, shopping cart, payment
- **Instant Messaging (IM)**: Real-time communication based on Socket.io, including private chat, group chat, friend list, group member management
- **Wallet & Asset Management**: Deposit, withdrawal, transaction records, coupons, virtual currency
- **Marketing & Activities**: Lucky draw, winner announcements
- **Security & Compliance**: KYC verification, ID scanning, liveness detection
- **Cross-Platform & Web Support**: PWA support, caching strategies, Web-specific adaptations

---

## 2. System Context & Boundaries

JoyMini client does not exist as an isolated node, but as the frontend neural endpoint of the entire distributed ecosystem.

### 2.1 Main Communication (Main API)

Based on HTTP/HTTPS Restful services, handling core transactions, user authentication, and product data. The client implements global Token scheduling and seamless refresh through `UnifiedInterceptor`.

### 2.2 Signaling Tunnel (WebSocket & FCM)

* **Socket.io**: Provides low-latency full-duplex channels, supporting millisecond-level hot-swap for `group_update` (group buying status) and `chat_message` (chat flow).
* **FCM (Firebase)**: Provides system-level offline channels. Not only handles regular push notifications, but also carries `call_invite` audio/video underlying handshake signaling, directly waking up native CallKit.

### 2.3 Compliance & Hardware Gateway (Native Integrations)

* **AWS Amplify Liveness**: Bridges native layer for 3D liveness detection interception.
* **Google ML Kit / VisionKit**: Takes over terminal hardware computing power, achieving offline noise reduction and pre-parsing for ID OCR.

### 2.4 Operations & Infrastructure Layer (DevOps)

Establishes OTA hot-update channel through Shorebird, closes CI/CD delivery status loop through Telegram Bot.

---

## 3. Core Layered Model

The project strictly follows **Domain-Driven Design (DDD)** and **Single Responsibility Principle (SRP)**, dividing the system into five layers with strict prohibition of cross-layer reverse calls.

### 3.1 Presentation / UI Layer

* **Positioning**: Pure visual renderer.
* **Implementation**: `Widget` contains no async network requests or data calculations. Gets state by monitoring Provider, executes actions by triggering Logic layer methods.
* **Defense**: Uses `RepaintBoundary` throughout to physically isolate high-frequency animations (countdowns, skeletons), and locks pixel-level visual sovereignty with Design Token (`design_tokens.g.dart`).

### 3.2 Logic / Controller Layer

* **Positioning**: Business hub between UI and state.
* **Implementation**: Uses `Mixin` pattern (e.g., `WithdrawPageLogic`, `OrderItemLogic`). Takes over form reactive validation (Reactive Forms), route navigation, popup scheduling, and initiates `Action` to State layer.
* **Benefits**: Breaks down UI pages that could be thousands of lines, making business flow logic readable and unit-testable.

### 3.3 State Management Layer (The Brain)

* **Positioning**: Single source of truth for global data.
* **Implementation**: Built on **Riverpod 2.0** (`AsyncNotifier`, `Provider`). Uses reactive graph mechanism to manage SWR (Stale-While-Revalidate) cache flow and dirty flag self-healing chains.

### 3.4 Domain / DTO Layer (Anti-Corruption Layer)

* **Positioning**: Shield against backend heterogeneous dirty data.
* **Implementation**: All entities (e.g., `OrderItem`, `KycMe`) enforce `checked: true`. Deploys strong type converters (e.g., `JsonNumConverter`) to ensure 100% compliance of data entering memory from backend, physically intercepting null pointer and type drift (e.g., String to int) crashes.

### 3.5 Infrastructure Layer

* **Positioning**: Direct communicator with hardware, disk, and network.
* **Implementation**:
  * **Storage**: `ApiCacheManager` (Hive / SharedPreferences intelligent routing) and Sembast (local IM message library).
  * **Network**: `http_adapter_factory.dart` (conditional export solving cross-platform conflicts).
  * **Bridge**: `MethodChannel` wrapper classes, handling dual-platform native hardware interaction.

---

## 4. Technology Stack

### 4.1 Core Framework

| Category | Technology | Version | Purpose |
|----------|------------|---------|---------|
| Development Framework | Flutter SDK | >=3.10.0 <4.0.0 | Cross-platform development |
| State Management | Riverpod | 2.0 | Dependency injection and global state sharing |
| Routing Management | GoRouter | - | Declarative routing, authentication, DeepLink |

### 4.2 Network & Communication

| Category | Technology | Purpose |
|----------|------------|---------|
| HTTP Client | Dio | Core network requests, Token seamless refresh |
| WebSocket | socket_io_client | Real-time communication, group buying status sync |
| Native Adapter | native_dio_adapter | Improve native network performance |

### 4.3 Data Persistence

| Category | Technology | Purpose |
|----------|------------|---------|
| KV Storage | shared_preferences | Basic key-value storage |
| Secure Storage | flutter_secure_storage | Sensitive information storage |
| Local Database | Hive | Complex data model caching |
| Local IM Library | Sembast | Chat record storage |

### 4.4 UI & Internationalization

| Category | Technology | Purpose |
|----------|------------|---------|
| Screen Adaptation | flutter_screenutil | Fine-grained screen adaptive layout |
| Internationalization | easy_localization | Multi-language support (en, tl) |
| Design System | design_tokens | Highly customizable design system |

### 4.5 Hardware & Media Processing

| Category | Technology | Purpose |
|----------|------------|---------|
| Camera | camera | Photo, scan |
| Image Picker | image_picker | Image selection |
| File Picker | file_picker | File upload |
| Audio | just_audio | Audio playback |
| Recording | record | Voice recording |
| Video Processing | ffmpeg_kit_flutter_new | Video editing |
| OCR | google_mlkit_text_recognition | Text recognition |
| Face Detection | google_mlkit_face_detection | Face recognition |

---

## 5. Directory Structure

The project adopts a relatively standardized layered architecture (similar to Clean Architecture combined with layered design), with clear separation of responsibilities:

### 5.1 `lib/app/` (Application Layer)

Responsible for page rendering and route navigation.

* `page/`: Page files aggregated by business module (e.g., `home`, `product`, `login`, `chat`, `kyc_verify`, `deposit`, etc.).
* `routes/`: Global route configuration center. Not only defines page mappings, but also handles authentication redirection, parameter encoding/decoding (`ExtraCodec`), and custom page transition animations.
* `bootstrap.dart`, `app_startup.dart`: Application lifecycle starting point, responsible for environment initialization and dependency injection warmup before UI rendering, forming "data barrier".

### 5.2 `lib/core/` (Core Logic Layer)

Stores core business logic and data-driven code unrelated to specific UI.

* `api/`, `network/`: Network layer implementation. Wraps Dio configuration, interceptors (`UnifiedInterceptor`), and API interface declarations for various backends.
* `providers/`: State layer implementation. Centralized storage of various Riverpod Providers (e.g., `auth_provider`, `wallet_provider`, `socket_provider`), serving as bridge between network layer and UI layer.
* `models/`: Data model layer, combined with `json_serializable` for data serialization.

### 5.3 `lib/components/` (Business Component Layer)

Carries reusable component modules with specific business logic, such as homepage Banner (`home_banner`), KYC verification popup (`kyc_modal`), product card (`product_item`).

### 5.4 `lib/ui/` (Basic Visual Component Layer)

Pure visual UI component encapsulation, completely decoupled from business. Contains various atomic components: buttons, animations, popup modals (`ui/modal/`), Toast, etc.

### 5.5 `lib/utils/` (Utility Layer)

Global utility set. Includes date processing, device information reading, animation assistance, and PWA cross-platform judgment assistance.

---

## 6. Architecture Decision Records

### ADR-001: Abandon GetX, Embrace Riverpod 2.0 Reactive Foundation

* **Background**: The application has extremely complex cross-page state linkages (e.g., payment success -> refresh balance -> refresh transaction list -> mark homepage update).
* **Decision**: Introduce Riverpod 2.0 to build state tree.
* **Benefits**:
  * **Compile-time Safety**: Avoids runtime crashes from GetX string addressing or Provider tree hierarchy not found.
  * **Authentication Self-Destruction Mechanism**: Through `ref.watch(authProvider)`, all memory-sensitive caches (e.g., order lists) are automatically garbage collected by Riverpod engine when user logs out, physically eliminating "multi-account data leakage" disease.

### ADR-002: Break GoRouter Limitations, Self-Develop Type-Safe Codec (CommonExtraCodec)

* **Background**: GoRouter natively doesn't support passing complex custom objects across pages (causing object loss after refresh or DeepLink crashes).
* **Decision**: Establish registry model based on `BaseRouteArgs` in `extra_codec.dart`, and mount custom Codec at Router底层.
* **Benefits**: Achieves automatic injection of `__type__` fingerprint and serialization when routes are pushed, enabling `ProductListItem` and other large entities to pass 100% losslessly between pages, perfectly compatible with Web URL sharing.

### ADR-003: Adopt SWR (Stale-While-Revalidate) to End Full-Screen Loading

* **Background**: Regular network requests cause brief white screens or spinning circles, greatly affecting e-commerce and social immersion.
* **Decision**: Through wrapping `ApiCacheManager` combined with Riverpod's `AsyncValue`, establish SWR loading paradigm.
* **Benefits**: Route entry instant (0ms) uses disk cache to build high-fidelity UI, while background silently fetches latest data concurrently. After new data arrives, through object difference comparison, only executes local repaint when underlying data changes (`skipLoadingOnReload`).

### ADR-004: Complex List Governance Based on Mixin and Adapter (PageListViewPro)

* **Background**: Flutter native `ListView` causes UI code to膨胀急剧 (often thousands of lines) when handling pull-to-refresh, load-more, error fallback, and skeleton screens.
* **Decision**:剥离 `PageListController` state machine, combine with `PageListViewPro`, and introduce `toUiModel()` adapter pattern (e.g., `TransactionUiModel`) at business layer.
* **Benefits**: Completely decouples UI rendering from pagination control, achieving "regardless of what heterogeneous transaction data backend gives, frontend一律洗成同构模型渲染", code reuse rate improved by 80%.

### ADR-005: Financial Precision Anti-Corruption and Type Physical Lock

* **Background**: Dart's `double` type极易因后端返回数据类型漂移导致崩溃 when processing cross-platform JSON parsing.
* **Decision**: All transaction entities enforce `@JsonSerializable(checked: true)`, enforce `JsonNumConverter.toDouble`.
* **Benefits**: Even if backend spits dirty data, it's forced to clean into strong type before entering memory, establishing frontend's "absolute sovereignty" in asset display.

### ADR-006: Authentication-Driven Cache Self-Destruction Mechanism

* **Background**: Traditional approach requires manually clearing various variables in logout() method, easily遗漏导致跨账号数据串流.
* **Decision**: Use Riverpod 2.0's dependency tracking graph,让 sensitive data Provider enforce monitoring authentication state.
* **Benefits**: When user logs out or Token expires, system automatically discards old Provider instance, physically销毁 internal cache Map, eliminating cross-account data leakage disease.

### ADR-007: Interceptor UI Zero-Coupling Principle

* **Background**: Traditional Dio interceptors often need to依赖 current BuildContext to弹窗 or跳路由 when handling 401 logout, causing red screen crashes.
* **Decision**: onTokenInvalid in interceptors严禁传递 Context, must directly call底层 authNotifier.logout() through global singleton ProviderContainer.
* **Benefits**: Data layer changes naturally drive upper UI layer route redirection, completely decoupled.

---

## 7. Architecture Rules

To ensure codebase purity during team expansion and long-term evolution, establish the following architecture-level red lines that任何人不可逾越:

### 7.1 Financial Precision不可篡改

All DTO fields involving funds, ratios, thresholds严禁使用 native `double` parsing, must强挂载 `@JsonKey(fromJson: JsonNumConverter.toDouble)`.

### 7.2 UI无头脑原则

`build()` method内严禁出现超过 3 行的复杂业务计算. All judgments (e.g., `canRequestRefund`) must内聚在 Model's `get` method, all behavior side effects must托管在 `Logic` or `Notifier`.

### 7.3 Design Sovereignty System Generation

严禁在 UI 中手写如 `Color(0xFF0000)` or `height: 24`. All design parameters must通过 `gen_tokens_flutter.dart` 从 Figma 源文件中编译生成,捍卫多端视觉对齐的绝对主权.

### 7.4 Logic Cohesion Red Line

UI's `build` tree中绝对不允许出现状态判定逻辑 (e.g., `if (status == 3 && payStatus == 1)`), must封装在 DTO 内部作为 `get` 属性 (e.g., `item.canRequestRefund`).

### 7.5 Cross-Domain Isolation Red Line

Transaction domain (Wallet/Payment) state updates严禁直接去调用 UI domain interfaces. Must通过修改对应的 `DirtyProvider` (脏标记),让 UI domain自行决定在"合适的时机 (e.g., page visible时)"去刷新.

---

## 8. Related Documents

### Core Architecture Documents

* **[Core Domain Design.md](./Core%20Domain%20Design.md)** - Core domain design, including detailed design for financial, IM, authentication三大领域
* **[Design System Automation.md](./Design%20System%20Automation.md)** - UI/UX asset automation, design token generation and cross-platform adaptation

### Other Related Documents

* **[AI Quick Start Guide](../AI_QUICK_START.md)** - AI quick start guide
* **[Error Patterns](../ERROR_PATTERNS.md)** - Common error patterns and solutions
* **[Flutter Commands Cheatsheet](../FLUTTER_COMMANDS_CHEATSHEET.md)** - Flutter command quick reference
* **[AI Collaboration Workflow](../AI_COLLABORATION_WORKFLOW.md)** - AI collaboration workflow

---

## 📊 Document Maintenance

**Document Status**: ✅ Active  
**Maintainer**: AI Assistant + Development Team  
**Update Frequency**: Continuously updated with architecture evolution  
**Review Cycle**: Monthly

---

**Last Updated**: 2026-03-28  
**Document Version**: v12.0  
**Consolidation Source**: Top-Level Architecture Blueprint.md, PROJECT_ARCHITECTURE_SUMMARY.md