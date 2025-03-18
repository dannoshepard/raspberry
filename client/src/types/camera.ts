export interface CameraSettings {
  focus: number;
  backlightEnabled: boolean;
}

export interface VideoStream {
  url: string;
  timestamp: string;
  onRecordingStateChange: (isRecording: boolean) => void;
}

export interface CameraControls {
  onFocusChange: (value: number) => void;
  onBacklightToggle: (enabled: boolean) => void;
  settings: CameraSettings;
} 