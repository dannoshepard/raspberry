'use client';

import { useEffect, useRef, useState } from 'react';
import { VideoStream as VideoStreamType } from '@/types/camera';

// Helper function to get supported MIME type
function getSupportedMimeType() {
  const types = [
    'video/webm;codecs=vp9',
    'video/webm;codecs=vp8',
    'video/webm',
    'video/mp4'
  ];

  for (const type of types) {
    if (MediaRecorder.isTypeSupported(type)) {
      return type;
    }
  }
  return null;
}

export default function VideoStream({ url, timestamp, onRecordingStateChange }: VideoStreamType) {
  const imgRef = useRef<HTMLImageElement>(null);
  const [isRecording, setIsRecording] = useState(false);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const img = imgRef.current;
    if (!img) return;

    // Set image source
    img.src = url;

    // Handle image errors
    const handleError = (e: Event) => {
      console.error('Image error:', e);
      setError('Failed to load video stream. Retrying...');
      // Retry loading after a short delay
      setTimeout(() => {
        if (imgRef.current) {
          imgRef.current.src = url;
        }
      }, 1000);
    };

    // Handle successful load
    const handleLoad = () => {
      setError(null);
    };

    img.addEventListener('error', handleError);
    img.addEventListener('load', handleLoad);

    return () => {
      img.removeEventListener('error', handleError);
      img.removeEventListener('load', handleLoad);
      img.src = '';
    };
  }, [url]);

  const startRecording = () => {
    const img = imgRef.current;
    if (!img) return;

    // Check for supported MIME type
    const mimeType = getSupportedMimeType();
    if (!mimeType) {
      console.error('No supported video MIME types found');
      alert('Your browser does not support video recording');
      return;
    }

    // Create a canvas element to capture the image stream
    const canvas = document.createElement('canvas');
    canvas.width = img.naturalWidth || 640; // Use natural dimensions
    canvas.height = img.naturalHeight || 480;
    const ctx = canvas.getContext('2d');
    
    // Create a media stream from the canvas
    const stream = canvas.captureStream(30); // 30 fps
    const mediaRecorder = new MediaRecorder(stream, {
      mimeType: mimeType
    });

    // Start drawing frames to canvas
    const drawFrame = () => {
      if (ctx && isRecording && img.complete) {
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        requestAnimationFrame(drawFrame);
      }
    };

    mediaRecorder.ondataavailable = (event) => {
      if (event.data.size > 0) {
        chunksRef.current.push(event.data);
      }
    };

    mediaRecorder.onstop = () => {
      const blob = new Blob(chunksRef.current, { type: mimeType });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `camera_feed_${new Date().toISOString().replace(/[:.]/g, '-')}.${mimeType.includes('mp4') ? 'mp4' : 'webm'}`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      chunksRef.current = [];
    };

    mediaRecorderRef.current = mediaRecorder;
    mediaRecorder.start();
    setIsRecording(true);
    onRecordingStateChange(true);
    requestAnimationFrame(drawFrame);
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
      mediaRecorderRef.current.stop();
      setIsRecording(false);
      onRecordingStateChange(false);
    }
  };

  return (
    <div className="relative bg-black rounded-lg overflow-hidden">
      <img
        ref={imgRef}
        className="w-full h-auto"
        style={{ objectFit: 'contain' }}
        alt="Camera feed"
      />
      {error && (
        <div className="absolute top-4 left-4 right-4 bg-red-500 text-white px-4 py-2 rounded text-center">
          {error}
        </div>
      )}
      <div className="absolute bottom-4 right-4 bg-black/50 text-white px-2 py-1 rounded">
        {timestamp}
      </div>
      <button
        onClick={isRecording ? stopRecording : startRecording}
        className={`absolute bottom-4 left-4 px-4 py-2 rounded ${
          isRecording
            ? 'bg-red-500 hover:bg-red-600'
            : 'bg-green-500 hover:bg-green-600'
        } text-white font-semibold`}
      >
        {isRecording ? 'Stop Recording' : 'Start Recording'}
      </button>
    </div>
  );
} 