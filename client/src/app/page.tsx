'use client';

import { useState, useEffect } from 'react';
import VideoStream from '@/components/VideoStream';
import CameraControls from '@/components/CameraControls';
import { CameraSettings } from '@/types/camera';

export default function Home() {
  const [settings, setSettings] = useState<CameraSettings>({
    focus: 30,
    backlightEnabled: true
  });
  const streamUrl = 'http://10.0.0.2:5000/video_feed';
  const [timestamp, setTimestamp] = useState('');

  useEffect(() => {
    // Set initial timestamp
    setTimestamp(new Date().toLocaleTimeString());

    // Update timestamp every second
    const interval = setInterval(() => {
      setTimestamp(new Date().toLocaleTimeString());
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  const handleFocusChange = async (value: number) => {
    try {
      const response = await fetch(`http://10.0.0.2:5000/set_focus/${value}`);
      if (response.ok) {
        setSettings(prev => ({ ...prev, focus: value }));
      }
    } catch (error) {
      console.error('Error setting focus:', error);
    }
  };

  const handleBacklightToggle = async (enabled: boolean) => {
    try {
      const response = await fetch(`http://10.0.0.2:5000/set_backlight/${enabled ? 1 : 0}`);
      if (response.ok) {
        setSettings(prev => ({ ...prev, backlightEnabled: enabled }));
      }
    } catch (error) {
      console.error('Error toggling backlight:', error);
    }
  };

  return (
    <main className="min-h-screen bg-gray-100 py-8">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl font-bold text-gray-900 mb-8 text-center">
          Camera Control Panel
        </h1>
        
        <div className="bg-white rounded-lg shadow-lg p-6">
          <VideoStream
            url={streamUrl}
            timestamp={timestamp}
            onRecordingStateChange={() => {}}
          />
          
          <div className="mt-6">
            <CameraControls
              onFocusChange={handleFocusChange}
              onBacklightToggle={handleBacklightToggle}
              settings={settings}
            />
          </div>
        </div>
      </div>
    </main>
  );
}
