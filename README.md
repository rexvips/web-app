# Daily Routine App with Meditation

A production-grade iOS application for tracking daily routines with integrated meditation features, built using SwiftUI and following Clean Architecture principles.

## 🎯 Features

### Core Functionality
- **Daily Routine Tracking**: Create, manage, and track completion of daily routines
- **Smart Notifications**: Intelligent reminders for routines and meditation sessions
- **Progress Analytics**: Detailed insights into habit formation and streak tracking
- **CloudKit Sync**: Seamless data synchronization across all your Apple devices

### Meditation Module
- **Box Breathing**: Configurable 4-4-4-4 breathing pattern with audio cues
- **4-7-8 Breathing**: Relaxing breathing technique for stress relief
- **High-Precision Timing**: 60fps precision using CADisplayLink for accurate guidance
- **Background Audio**: Continues meditation sessions even when app is backgrounded
- **Ambient Sounds**: Nature sounds and white noise for enhanced focus
- **Haptic Feedback**: Subtle vibrations to guide breathing without audio

### Health Integration
- **HealthKit**: Automatic meditation session logging
- **Heart Rate Monitoring**: Track physiological changes during meditation
- **Mindfulness Minutes**: Contribute to Apple Health mindfulness data

## 🏗 Architecture

This application follows **Clean Architecture** principles with a **MVVM + Coordinator** pattern:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   SwiftUI   │  │  ViewModels │  │    Coordinators     │  │
│  │    Views    │  │             │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Entities   │  │  Use Cases  │  │   Repository        │  │
│  │             │  │             │  │   Protocols         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Core Data  │  │  CloudKit   │  │    Repositories     │  │
│  │             │  │             │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Services Layer                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Notification│  │    Audio    │  │      HealthKit      │  │
│  │   Service   │  │   Service   │  │      Service        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

1. **Protocol-Oriented Programming**: Heavy use of protocols for testability and flexibility
2. **Dependency Injection**: Centralized DI container for managing dependencies
3. **Reactive Programming**: Combine framework for reactive UI updates
4. **High-Precision Timing**: CADisplayLink for 60fps meditation timer accuracy
5. **Background Task Management**: Proper handling of background meditation sessions

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+
- macOS 13.0+ (for development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/daily-routine-app.git
   cd daily-routine-app
   ```

2. **Open in Xcode**
   ```bash
   open DailyRoutineApp.xcodeproj
   ```

3. **Configure signing**
   - Select your development team in Project Settings
   - Update bundle identifier if needed

4. **Set up CloudKit** (Optional)
   - Enable CloudKit capability in project settings
   - Configure CloudKit schema in CloudKit Console

5. **Build and run**
   - Select target device/simulator
   - Press ⌘+R to build and run

### First Launch Setup

The app will request the following permissions on first launch:
- **Notifications**: For routine and meditation reminders
- **HealthKit**: For meditation session tracking (optional)

## 🧪 Testing

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme DailyRoutineApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Run unit tests only
xcodebuild test -scheme DailyRoutineApp -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:DailyRoutineAppTests

# Run UI tests only
xcodebuild test -scheme DailyRoutineApp -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:DailyRoutineAppUITests
```

### Test Coverage

- **Unit Tests**: Core business logic, use cases, and services
- **UI Tests**: Critical user flows and meditation session functionality
- **Performance Tests**: Meditation timer precision and app launch performance

### Key Test Areas

1. **Meditation Timer Accuracy**: Ensures breathing guidance timing is precise
2. **Audio Session Management**: Tests background audio functionality
3. **Notification Scheduling**: Verifies reminder notifications work correctly
4. **Data Persistence**: Tests Core Data and CloudKit integration
5. **User Interface Flows**: Critical user journeys through UI tests

## 🛠 Development

### Code Quality

We use **SwiftLint** for code style consistency:

```bash
# Install SwiftLint
brew install swiftlint

# Run linting
swiftlint

# Auto-fix violations
swiftlint --fix
```

### Project Structure

```
DailyRoutineApp/
├── Sources/
│   ├── App/                     # App entry point
│   ├── Core/                    # Core utilities and dependencies
│   │   ├── Dependencies/        # Dependency injection
│   │   ├── Protocols/           # Core protocols
│   │   └── Utilities/           # Logging, analytics
│   ├── Data/                    # Data persistence layer
│   │   └── CoreData/           # Core Data stack
│   ├── Domain/                  # Business logic layer
│   │   ├── Entities/           # Domain models
│   │   ├── RepositoryProtocols/ # Repository interfaces
│   │   └── UseCases/           # Business use cases
│   ├── Presentation/           # UI layer
│   │   ├── Coordinators/       # Navigation coordinators
│   │   ├── ViewModels/         # View models
│   │   └── Views/              # SwiftUI views
│   └── Services/               # External services
├── Tests/                      # Test files
│   ├── DailyRoutineAppTests/   # Unit tests
│   └── DailyRoutineAppUITests/ # UI tests
└── Resources/                  # Assets, sounds, etc.
```

### Key Components

#### MeditationTimer
High-precision timer using CADisplayLink for accurate breathing guidance:

```swift
class MeditationTimer: ObservableObject {
    private var displayLink: CADisplayLink?
    
    func start(with settings: MeditationSettings) {
        displayLink = CADisplayLink(target: self, selector: #selector(timerTick))
        displayLink?.add(to: .main, forMode: .common)
    }
}
```

#### Audio Service
Manages background audio and breathing cues:

```swift
protocol AudioServiceProtocol {
    func playBreathingCue(for phase: BreathingPhase) async
    func configureAudioSession(for category: AVAudioSession.Category) async throws
    func startBackgroundAudio() async throws
}
```

## 📱 User Interface

### Main Sections

1. **Dashboard**: Overview of today's routines and progress
2. **Routines**: Create and manage daily routines
3. **Meditation**: Box breathing and 4-7-8 breathing sessions
4. **Settings**: App configuration and preferences

### Meditation Session Flow

1. **Selection**: Choose between Box Breathing or 4-7-8 Breathing
2. **Customization**: Adjust timing, enable audio cues and haptic feedback
3. **Session**: Follow visual and audio guidance
4. **Completion**: Review session stats and add notes

## 🔧 Configuration

### Meditation Settings

Users can customize:
- **Session Duration**: 1-60 minutes
- **Breathing Timing**: Configurable for each phase
- **Audio Cues**: Enable/disable breathing guidance sounds
- **Haptic Feedback**: Subtle vibrations for breathing cues
- **Ambient Sounds**: Background nature sounds

### Notification Settings

- **Routine Reminders**: Daily notifications for incomplete routines
- **Meditation Reminders**: Customizable meditation session reminders
- **Achievement Notifications**: Streak milestones and accomplishments

## 🚀 Deployment

### App Store Preparation

1. **Update version and build numbers**
2. **Configure release signing**
3. **Run all tests and ensure they pass**
4. **Archive the project**
5. **Submit to App Store Connect**

### Release Checklist

- [ ] All tests passing
- [ ] SwiftLint warnings resolved
- [ ] App Store screenshots updated
- [ ] Privacy policy updated
- [ ] App Store description finalized
- [ ] TestFlight beta testing completed

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the existing code style and architecture
4. Add tests for new functionality
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Standards

- Follow Swift API Design Guidelines
- Use SwiftLint configuration provided
- Write unit tests for business logic
- Document public APIs with DocC comments
- Follow Clean Architecture principles

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Apple Developer Documentation**: For comprehensive iOS development guidance
- **Clean Architecture**: Robert C. Martin's architectural principles
- **Meditation Techniques**: Evidence-based breathing practices
- **SwiftUI**: Apple's modern UI framework

## 📞 Support

For questions, issues, or feature requests:

1. Check existing [Issues](https://github.com/your-username/daily-routine-app/issues)
2. Create a new issue with detailed description
3. For urgent matters, contact [your-email@example.com](mailto:your-email@example.com)

---

**Built with ❤️ using SwiftUI and Clean Architecture principles**