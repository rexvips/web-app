// Daily Routine & Meditation App
// Progressive Web App Implementation

class DailyRoutineApp {
    constructor() {
        this.currentTab = 'dashboard';
        this.meditationState = {
            isActive: false,
            isPaused: false,
            currentType: null,
            startTime: null,
            duration: 300, // 5 minutes default
            currentPhase: 'inhale',
            phaseStartTime: null,
            phaseDuration: 4,
            cycle: 0,
            timer: null,
            audioEnabled: true,
            hapticEnabled: true,
            cueInterval: 4
        };
        
        this.init();
    }
    
    init() {
        this.setupNavigation();
        this.setupMeditationControls();
        this.requestNotificationPermission();
        this.loadUserPreferences();
        
        // Setup haptic feedback if supported
        if ('vibrate' in navigator) {
            console.log('Haptic feedback supported');
        }
    }
    
    // Navigation System
    setupNavigation() {
        const navButtons = document.querySelectorAll('.nav-btn');
        
        navButtons.forEach(btn => {
            btn.addEventListener('click', (e) => {
                const tabName = btn.dataset.tab;
                this.switchTab(tabName);
            });
        });
    }
    
    switchTab(tabName) {
        // Update navigation
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
        
        // Update content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        document.getElementById(`${tabName}-tab`).classList.add('active');
        
        this.currentTab = tabName;
    }
    
    // Meditation System
    setupMeditationControls() {
        const cueIntervalSelect = document.getElementById('cue-interval');
        const audioCheckbox = document.getElementById('audio-cues');
        const hapticCheckbox = document.getElementById('haptic-feedback');
        
        if (cueIntervalSelect) {
            cueIntervalSelect.addEventListener('change', (e) => {
                this.meditationState.cueInterval = parseInt(e.target.value);
                this.saveUserPreferences();
            });
        }
        
        if (audioCheckbox) {
            audioCheckbox.addEventListener('change', (e) => {
                this.meditationState.audioEnabled = e.target.checked;
                this.saveUserPreferences();
            });
        }
        
        if (hapticCheckbox) {
            hapticCheckbox.addEventListener('change', (e) => {
                this.meditationState.hapticEnabled = e.target.checked;
                this.saveUserPreferences();
            });
        }
    }
    
    startBoxBreathing() {
        this.meditationState.currentType = 'box';
        this.showMeditationSession('Box Breathing');
        this.resetMeditationState();
    }
    
    startFourSevenEight() {
        this.meditationState.currentType = '478';
        this.showMeditationSession('4-7-8 Breathing');
        this.resetMeditationState();
    }
    
    showMeditationSession(title) {
        document.getElementById('session-type').textContent = title;
        document.getElementById('meditation-session').classList.remove('hidden');
        
        // Update total time display
        const totalTimeDisplay = document.getElementById('total-time');
        const minutes = Math.floor(this.meditationState.duration / 60);
        const seconds = this.meditationState.duration % 60;
        totalTimeDisplay.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }
    
    resetMeditationState() {
        this.meditationState.isActive = false;
        this.meditationState.isPaused = false;
        this.meditationState.startTime = null;
        this.meditationState.currentPhase = 'inhale';
        this.meditationState.phaseStartTime = null;
        this.meditationState.cycle = 0;
        
        if (this.meditationState.timer) {
            clearInterval(this.meditationState.timer);
            this.meditationState.timer = null;
        }
        
        this.updateBreathingDisplay();
        this.updatePlayPauseButton();
    }
    
    toggleMeditation() {
        if (!this.meditationState.isActive) {
            this.startMeditation();
        } else if (this.meditationState.isPaused) {
            this.resumeMeditation();
        } else {
            this.pauseMeditation();
        }
    }
    
    startMeditation() {
        this.meditationState.isActive = true;
        this.meditationState.isPaused = false;
        this.meditationState.startTime = Date.now();
        this.meditationState.phaseStartTime = Date.now();
        
        this.updatePlayPauseButton();
        this.startBreathingCycle();
        this.startTimer();
        
        // Play start sound
        this.playAudioCue('start');
        this.triggerHaptic('start');
    }
    
    pauseMeditation() {
        this.meditationState.isPaused = true;
        this.updatePlayPauseButton();
        
        if (this.meditationState.timer) {
            clearInterval(this.meditationState.timer);
            this.meditationState.timer = null;
        }
    }
    
    resumeMeditation() {
        this.meditationState.isPaused = false;
        this.meditationState.phaseStartTime = Date.now() - (this.getPhaseProgress() * this.getCurrentPhaseDuration() * 1000);
        
        this.updatePlayPauseButton();
        this.startTimer();
    }
    
    stopMeditation() {
        this.resetMeditationState();
        document.getElementById('meditation-session').classList.add('hidden');
        
        // Track completion
        this.trackMeditationCompletion();
    }
    
    startTimer() {
        this.meditationState.timer = setInterval(() => {
            this.updateMeditationProgress();
            this.updateBreathingPhase();
        }, 100); // 10fps for smooth updates
    }
    
    updateMeditationProgress() {
        if (!this.meditationState.isActive || this.meditationState.isPaused) return;
        
        const elapsedTime = (Date.now() - this.meditationState.startTime) / 1000;
        const minutes = Math.floor(elapsedTime / 60);
        const seconds = Math.floor(elapsedTime % 60);
        
        document.getElementById('elapsed-time').textContent = 
            `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        
        // Check if session is complete
        if (elapsedTime >= this.meditationState.duration) {
            this.completeMeditation();
        }
    }
    
    updateBreathingPhase() {
        if (!this.meditationState.isActive || this.meditationState.isPaused) return;
        
        const phaseElapsed = (Date.now() - this.meditationState.phaseStartTime) / 1000;
        const phaseDuration = this.getCurrentPhaseDuration();
        
        if (phaseElapsed >= phaseDuration) {
            this.nextBreathingPhase();
        } else {
            // Update countdown
            const remaining = Math.ceil(phaseDuration - phaseElapsed);
            document.getElementById('breathing-count').textContent = remaining;
            
            // Update breathing circle animation
            this.updateBreathingAnimation(phaseElapsed / phaseDuration);
        }
    }
    
    nextBreathingPhase() {
        this.meditationState.phaseStartTime = Date.now();
        
        if (this.meditationState.currentType === 'box') {
            const phases = ['inhale', 'hold1', 'exhale', 'hold2'];
            const currentIndex = phases.indexOf(this.meditationState.currentPhase);
            const nextIndex = (currentIndex + 1) % phases.length;
            this.meditationState.currentPhase = phases[nextIndex];
            
            if (nextIndex === 0) {
                this.meditationState.cycle++;
            }
        } else if (this.meditationState.currentType === '478') {
            const phases = ['inhale', 'hold', 'exhale'];
            const currentIndex = phases.indexOf(this.meditationState.currentPhase);
            const nextIndex = (currentIndex + 1) % phases.length;
            this.meditationState.currentPhase = phases[nextIndex];
            
            if (nextIndex === 0) {
                this.meditationState.cycle++;
            }
        }
        
        this.updateBreathingDisplay();
        this.playAudioCue(this.meditationState.currentPhase);
        this.triggerHaptic(this.meditationState.currentPhase);
    }
    
    getCurrentPhaseDuration() {
        const interval = this.meditationState.cueInterval;
        
        if (this.meditationState.currentType === 'box') {
            return interval; // All phases same duration
        } else if (this.meditationState.currentType === '478') {
            switch (this.meditationState.currentPhase) {
                case 'inhale': return 4;
                case 'hold': return 7;
                case 'exhale': return 8;
                default: return 4;
            }
        }
        
        return interval;
    }
    
    updateBreathingDisplay() {
        const breathingText = document.getElementById('breathing-text');
        const breathingIndicator = document.getElementById('breathing-indicator');
        
        // Remove all phase classes
        breathingIndicator.classList.remove('inhaling', 'exhaling', 'holding');
        
        switch (this.meditationState.currentPhase) {
            case 'inhale':
                breathingText.textContent = 'Inhale';
                breathingIndicator.classList.add('inhaling');
                break;
            case 'hold1':
            case 'hold':
                breathingText.textContent = 'Hold';
                breathingIndicator.classList.add('holding');
                break;
            case 'exhale':
                breathingText.textContent = 'Exhale';
                breathingIndicator.classList.add('exhaling');
                break;
            case 'hold2':
                breathingText.textContent = 'Hold';
                breathingIndicator.classList.add('holding');
                break;
        }
        
        const duration = this.getCurrentPhaseDuration();
        document.getElementById('breathing-count').textContent = duration;
    }
    
    updateBreathingAnimation(progress) {
        const indicator = document.getElementById('breathing-indicator');
        
        if (this.meditationState.currentPhase === 'inhale') {
            const scale = 1 + (0.2 * progress);
            indicator.style.transform = `scale(${scale})`;
        } else if (this.meditationState.currentPhase === 'exhale') {
            const scale = 1.2 - (0.4 * progress);
            indicator.style.transform = `scale(${scale})`;
        }
    }
    
    getPhaseProgress() {
        const phaseElapsed = (Date.now() - this.meditationState.phaseStartTime) / 1000;
        const phaseDuration = this.getCurrentPhaseDuration();
        return Math.min(phaseElapsed / phaseDuration, 1);
    }
    
    updatePlayPauseButton() {
        const playPauseText = document.getElementById('play-pause-text');
        
        if (!this.meditationState.isActive) {
            playPauseText.textContent = 'Start';
        } else if (this.meditationState.isPaused) {
            playPauseText.textContent = 'Resume';
        } else {
            playPauseText.textContent = 'Pause';
        }
    }
    
    startBreathingCycle() {
        this.updateBreathingDisplay();
    }
    
    completeMeditation() {
        this.playAudioCue('complete');
        this.triggerHaptic('complete');
        
        // Show completion message
        setTimeout(() => {
            alert('Meditation session complete! Great job!');
            this.stopMeditation();
        }, 500);
    }
    
    // Audio System
    playAudioCue(type) {
        if (!this.meditationState.audioEnabled) return;
        
        try {
            // Create audio context for better control
            const audioContext = new (window.AudioContext || window.webkitAudioContext)();
            
            // Generate different tones for different phases
            const frequency = this.getFrequencyForPhase(type);
            this.playTone(audioContext, frequency, 0.3);
        } catch (error) {
            console.log('Audio not supported:', error);
        }
    }
    
    getFrequencyForPhase(phase) {
        switch (phase) {
            case 'inhale': return 440; // A4
            case 'hold': case 'hold1': case 'hold2': return 523; // C5
            case 'exhale': return 330; // E4
            case 'start': return 660; // E5
            case 'complete': return 880; // A5
            default: return 440;
        }
    }
    
    playTone(audioContext, frequency, duration) {
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        oscillator.frequency.setValueAtTime(frequency, audioContext.currentTime);
        oscillator.type = 'sine';
        
        gainNode.gain.setValueAtTime(0, audioContext.currentTime);
        gainNode.gain.linearRampToValueAtTime(0.1, audioContext.currentTime + 0.05);
        gainNode.gain.linearRampToValueAtTime(0, audioContext.currentTime + duration);
        
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + duration);
    }
    
    // Haptic Feedback
    triggerHaptic(type) {
        if (!this.meditationState.hapticEnabled) return;
        if (!('vibrate' in navigator)) return;
        
        let pattern;
        switch (type) {
            case 'inhale':
                pattern = [100];
                break;
            case 'hold':
            case 'hold1':
            case 'hold2':
                pattern = [50, 50, 50];
                break;
            case 'exhale':
                pattern = [200];
                break;
            case 'start':
                pattern = [100, 100, 100];
                break;
            case 'complete':
                pattern = [200, 100, 200, 100, 200];
                break;
            default:
                pattern = [50];
        }
        
        navigator.vibrate(pattern);
    }
    
    // Data Persistence
    saveUserPreferences() {
        const preferences = {
            audioEnabled: this.meditationState.audioEnabled,
            hapticEnabled: this.meditationState.hapticEnabled,
            cueInterval: this.meditationState.cueInterval
        };
        
        localStorage.setItem('dailyRoutinePreferences', JSON.stringify(preferences));
    }
    
    loadUserPreferences() {
        const saved = localStorage.getItem('dailyRoutinePreferences');
        if (saved) {
            const preferences = JSON.parse(saved);
            
            this.meditationState.audioEnabled = preferences.audioEnabled ?? true;
            this.meditationState.hapticEnabled = preferences.hapticEnabled ?? true;
            this.meditationState.cueInterval = preferences.cueInterval ?? 4;
            
            // Update UI
            const audioCheckbox = document.getElementById('audio-cues');
            const hapticCheckbox = document.getElementById('haptic-feedback');
            const cueIntervalSelect = document.getElementById('cue-interval');
            
            if (audioCheckbox) audioCheckbox.checked = this.meditationState.audioEnabled;
            if (hapticCheckbox) hapticCheckbox.checked = this.meditationState.hapticEnabled;
            if (cueIntervalSelect) cueIntervalSelect.value = this.meditationState.cueInterval;
        }
    }
    
    // Notifications
    async requestNotificationPermission() {
        if ('Notification' in window) {
            const permission = await Notification.requestPermission();
            console.log('Notification permission:', permission);
        }
    }
    
    // Analytics
    trackMeditationCompletion() {
        const sessionData = {
            type: this.meditationState.currentType,
            duration: this.meditationState.duration,
            cycles: this.meditationState.cycle,
            timestamp: new Date().toISOString()
        };
        
        // Save to local storage for now
        const sessions = JSON.parse(localStorage.getItem('meditationSessions') || '[]');
        sessions.push(sessionData);
        localStorage.setItem('meditationSessions', JSON.stringify(sessions));
        
        console.log('Meditation session completed:', sessionData);
    }
}

// Global Functions (called from HTML)
let app;

function startBoxBreathing() {
    app.startBoxBreathing();
}

function startFourSevenEight() {
    app.startFourSevenEight();
}

function toggleMeditation() {
    app.toggleMeditation();
}

function stopMeditation() {
    app.stopMeditation();
}

function addRoutine() {
    const name = prompt('Enter routine name:');
    if (name) {
        alert(`Routine "${name}" added!`);
        // Here you would typically save to storage
    }
}

// PWA Install Prompt
let deferredPrompt;

window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
});

function showInstallPrompt() {
    if (deferredPrompt) {
        deferredPrompt.prompt();
        deferredPrompt.userChoice.then((choiceResult) => {
            console.log(choiceResult.outcome);
            deferredPrompt = null;
        });
    } else {
        alert('App can be installed from your browser\'s menu or by adding to home screen.');
    }
}

// Initialize App
document.addEventListener('DOMContentLoaded', () => {
    app = new DailyRoutineApp();
});