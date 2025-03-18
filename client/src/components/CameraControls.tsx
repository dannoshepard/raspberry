import { CameraControls as CameraControlsType } from '@/types/camera';

export default function CameraControls({
  onFocusChange,
  onBacklightToggle,
  settings
}: CameraControlsType) {
  return (
    <div className="space-y-6">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Focus Control
        </label>
        <div className="flex items-center space-x-4">
          <input
            type="range"
            min="0"
            max="100"
            value={settings.focus}
            onChange={(e) => onFocusChange(Number(e.target.value))}
            className="flex-1 h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
          />
          <span className="text-sm font-medium text-gray-700 w-12 text-right">
            {settings.focus}
          </span>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Backlight Control
        </label>
        <button
          onClick={() => onBacklightToggle(!settings.backlightEnabled)}
          className={`px-4 py-2 rounded-md font-medium ${
            settings.backlightEnabled
              ? 'bg-green-500 hover:bg-green-600 text-white'
              : 'bg-gray-200 hover:bg-gray-300 text-gray-700'
          }`}
        >
          {settings.backlightEnabled ? 'Backlight On' : 'Backlight Off'}
        </button>
      </div>
    </div>
  );
} 