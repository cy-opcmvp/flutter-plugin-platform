# Weather Plugin (Python)

A weather information plugin demonstrating Plugin SDK usage with Python.

## Features

- Current weather conditions
- 5-day weather forecast
- Location-based weather data
- Weather alerts and notifications
- Configurable update intervals
- Multiple location support

## Getting Started

### Prerequisites

- Python 3.7+
- Plugin SDK for Python
- Internet connection for weather data

### Installation

1. Clone or download this example
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Configure API key in `config.json`
4. Build the plugin:
   ```bash
   plugin-cli build
   ```
5. Package for distribution:
   ```bash
   plugin-cli package --platform all --output weather.pkg
   ```

### Configuration

Create a `config.json` file with your weather API configuration:

```json
{
  "api_key": "your_weather_api_key",
  "default_location": "New York, NY",
  "update_interval": 300,
  "units": "metric"
}
```

### Testing

Test the plugin locally:

```bash
plugin-cli test --plugin weather.pkg
```

## Code Structure

```
python_weather/
├── main.py                   # Main entry point
├── weather_service.py        # Weather API integration
├── weather_ui.py            # User interface (if applicable)
├── config.json              # Configuration file
├── requirements.txt         # Python dependencies
├── plugin_manifest.json     # Plugin configuration
└── README.md               # This file
```

## Key SDK Features Demonstrated

1. **Async Plugin Architecture**: Using asyncio for non-blocking operations
2. **API Integration**: Fetching data from external weather APIs
3. **Configuration Management**: Loading and saving plugin settings
4. **Event Handling**: Responding to location changes and user requests
5. **Scheduled Tasks**: Periodic weather updates
6. **Error Handling**: Robust error handling for network issues
7. **Logging**: Comprehensive logging for debugging

## Usage

Once installed in the Flutter Plugin Platform:

1. Configure your preferred locations
2. Set update intervals and units
3. View current weather and forecasts
4. Receive weather alerts and notifications

## API Integration

The plugin demonstrates integration with:

- Weather API services (OpenWeatherMap, etc.)
- Host application APIs for notifications and preferences
- Location services for automatic location detection

## Development Notes

This example showcases best practices for Python-based external plugins:

- Async/await patterns for non-blocking operations
- Proper exception handling for network operations
- Configuration file management
- Logging and debugging support
- Clean separation of concerns (API, UI, logic)