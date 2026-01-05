#!/usr/bin/env python3
"""
Weather Plugin - External plugin for Flutter Plugin Platform

This plugin provides weather information and forecasts using external weather APIs.
Demonstrates Python-based plugin development with the Plugin SDK.
"""

import asyncio
import json
import logging
import sys
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

# from plugin_sdk import PluginSDK  # When SDK is available
from weather_service import WeatherService

class WeatherPlugin:
    """Main weather plugin class"""
    
    def __init__(self):
        self.plugin_id = "com.example.weather"
        self.name = "Weather Plugin"
        self.version = "1.0.0"
        self.logger = logging.getLogger(__name__)
        
        self.weather_service: Optional[WeatherService] = None
        self.config: Dict[str, Any] = {}
        self.update_task: Optional[asyncio.Task] = None
        self.is_running = False
        
    async def initialize(self):
        """Initialize the weather plugin"""
        self.logger.info(f"Initializing {self.name} v{self.version}")
        
        try:
            # Load configuration
            await self._load_configuration()
            
            # Initialize SDK when available
            # await PluginSDK.initialize(
            #     plugin_id=self.plugin_id,
            #     config={
            #         'name': self.name,
            #         'version': self.version,
            #         'type': 'tool',
            #     }
            # )
            
            # Set up event handlers
            # PluginSDK.on_host_event('location_changed', self._handle_location_change)
            # PluginSDK.on_host_event('settings_updated', self._handle_settings_update)
            # PluginSDK.on_host_event('weather_request', self._handle_weather_request)
            
            # Initialize weather service
            self.weather_service = WeatherService(
                api_key=self.config.get('api_key'),
                units=self.config.get('units', 'metric')
            )
            
            self.logger.info("Weather plugin initialized successfully")
            
        except Exception as e:
            self.logger.error(f"Failed to initialize weather plugin: {e}")
            # await PluginLifecycleHelper.report_error(
            #     'Initialization failed',
            #     {'error': str(e)}
            # )
            raise
            
    async def run(self):
        """Main plugin execution loop"""
        self.logger.info("Weather plugin is running...")
        self.is_running = True
        
        try:
            # Report plugin ready
            # await PluginLifecycleHelper.report_ready()
            
            # Start periodic weather updates
            self.update_task = asyncio.create_task(self._update_loop())
            
            # Keep plugin running
            while self.is_running:
                await asyncio.sleep(1)
                
        except asyncio.CancelledError:
            self.logger.info("Weather plugin execution cancelled")
        except Exception as e:
            self.logger.error(f"Weather plugin error: {e}")
            # await PluginLifecycleHelper.report_error(
            #     'Runtime error',
            #     {'error': str(e)}
            # )
            
    async def shutdown(self):
        """Cleanup and shutdown the plugin"""
        self.logger.info("Shutting down weather plugin...")
        self.is_running = False
        
        if self.update_task:
            self.update_task.cancel()
            try:
                await self.update_task
            except asyncio.CancelledError:
                pass
                
        # Save configuration
        await self._save_configuration()
        
        self.logger.info("Weather plugin shutdown complete")
        
    async def _load_configuration(self):
        """Load plugin configuration"""
        try:
            with open('config.json', 'r') as f:
                self.config = json.load(f)
                
            # Get additional config from host if available
            # host_config = await PluginSDK.get_plugin_config()
            # self.config.update(host_config)
            
            self.logger.info("Configuration loaded successfully")
            
        except FileNotFoundError:
            self.logger.warning("No config file found, using defaults")
            self.config = {
                'api_key': '',
                'default_location': 'New York, NY',
                'update_interval': 300,  # 5 minutes
                'units': 'metric',
                'locations': ['New York, NY']
            }
        except Exception as e:
            self.logger.error(f"Failed to load configuration: {e}")
            raise
            
    async def _save_configuration(self):
        """Save plugin configuration"""
        try:
            with open('config.json', 'w') as f:
                json.dump(self.config, f, indent=2)
                
            self.logger.info("Configuration saved successfully")
            
        except Exception as e:
            self.logger.error(f"Failed to save configuration: {e}")
            
    async def _update_loop(self):
        """Periodic weather update loop"""
        while self.is_running:
            try:
                await self._update_weather_data()
                
                # Wait for next update
                interval = self.config.get('update_interval', 300)
                await asyncio.sleep(interval)
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                self.logger.error(f"Weather update error: {e}")
                await asyncio.sleep(60)  # Retry after 1 minute
                
    async def _update_weather_data(self):
        """Update weather data for all configured locations"""
        if not self.weather_service:
            return
            
        locations = self.config.get('locations', [])
        
        for location in locations:
            try:
                # Get current weather
                current_weather = await self.weather_service.get_current_weather(location)
                
                # Get forecast
                forecast = await self.weather_service.get_forecast(location)
                
                # Send weather data to host
                # await PluginSDK.send_event('weather_updated', {
                #     'location': location,
                #     'current': current_weather,
                #     'forecast': forecast,
                #     'timestamp': datetime.now().isoformat()
                # })
                
                # Check for weather alerts
                await self._check_weather_alerts(location, current_weather)
                
                self.logger.debug(f"Updated weather data for {location}")
                
            except Exception as e:
                self.logger.error(f"Failed to update weather for {location}: {e}")
                
    async def _check_weather_alerts(self, location: str, weather_data: Dict[str, Any]):
        """Check for weather alerts and send notifications"""
        try:
            # Check for severe weather conditions
            alerts = []
            
            temp = weather_data.get('temperature', 0)
            condition = weather_data.get('condition', '').lower()
            
            # Temperature alerts
            if temp > 35:  # Hot weather
                alerts.append({
                    'type': 'heat_warning',
                    'message': f'High temperature alert: {temp}°C in {location}'
                })
            elif temp < -10:  # Cold weather
                alerts.append({
                    'type': 'cold_warning',
                    'message': f'Low temperature alert: {temp}°C in {location}'
                })
                
            # Condition alerts
            if any(word in condition for word in ['storm', 'tornado', 'hurricane']):
                alerts.append({
                    'type': 'severe_weather',
                    'message': f'Severe weather alert: {condition} in {location}'
                })
                
            # Send alerts as notifications
            for alert in alerts:
                # await PluginSDK.call_host_api('show_notification', {
                #     'title': 'Weather Alert',
                #     'message': alert['message'],
                #     'type': 'warning',
                #     'priority': 'high'
                # })
                
                self.logger.warning(f"Weather alert: {alert['message']}")
                
        except Exception as e:
            self.logger.error(f"Failed to check weather alerts: {e}")
            
    # Event handlers
    
    async def _handle_location_change(self, event_data: Dict[str, Any]):
        """Handle location change events from host"""
        try:
            new_location = event_data.get('location')
            if new_location:
                locations = self.config.get('locations', [])
                if new_location not in locations:
                    locations.append(new_location)
                    self.config['locations'] = locations
                    await self._save_configuration()
                    
                self.logger.info(f"Added new location: {new_location}")
                
        except Exception as e:
            self.logger.error(f"Failed to handle location change: {e}")
            
    async def _handle_settings_update(self, event_data: Dict[str, Any]):
        """Handle settings update events from host"""
        try:
            settings = event_data.get('settings', {})
            self.config.update(settings)
            await self._save_configuration()
            
            # Update weather service if units changed
            if 'units' in settings and self.weather_service:
                self.weather_service.units = settings['units']
                
            self.logger.info("Settings updated successfully")
            
        except Exception as e:
            self.logger.error(f"Failed to handle settings update: {e}")
            
    async def _handle_weather_request(self, event_data: Dict[str, Any]):
        """Handle weather data requests from host"""
        try:
            location = event_data.get('location')
            request_type = event_data.get('type', 'current')
            
            if not location or not self.weather_service:
                return
                
            if request_type == 'current':
                weather_data = await self.weather_service.get_current_weather(location)
            elif request_type == 'forecast':
                weather_data = await self.weather_service.get_forecast(location)
            else:
                self.logger.warning(f"Unknown weather request type: {request_type}")
                return
                
            # Send response
            # await PluginSDK.send_event('weather_response', {
            #     'location': location,
            #     'type': request_type,
            #     'data': weather_data,
            #     'timestamp': datetime.now().isoformat()
            # })
            
        except Exception as e:
            self.logger.error(f"Failed to handle weather request: {e}")


async def main():
    """Main entry point"""
    # Set up logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    plugin = WeatherPlugin()
    
    try:
        await plugin.initialize()
        await plugin.run()
    except KeyboardInterrupt:
        print("\nShutdown requested...")
    except Exception as e:
        logging.error(f"Plugin error: {e}")
        sys.exit(1)
    finally:
        await plugin.shutdown()


if __name__ == "__main__":
    asyncio.run(main())