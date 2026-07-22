//
//  WeatherService.swift
//  Ascendr
//
//  Weather service using iOS WeatherKit
//

import Foundation
import CoreLocation
import Combine

#if canImport(WeatherKit)
import WeatherKit
#endif

@MainActor
class WeatherService: NSObject, ObservableObject {
    static let shared = WeatherService()
    
    @Published var temperature: String = "--°"
    @Published var condition: String = "Loading..."
    @Published var temperatureRange: String = "--°"
    @Published var isLoading = false
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocationAndWeather() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services not enabled")
            return
        }
        
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            print("Location authorization denied")
        }
    }
    
    private func fetchWeatherWithWeatherKit(for location: CLLocation) async {
        isLoading = true
        
        #if canImport(WeatherKit)
        if #available(iOS 16.0, *) {
            do {
                // Use WeatherKit's WeatherService - this uses the same data as iOS Weather app
                // WeatherKit requires proper configuration in Apple Developer portal:
                // 1. Create a WeatherKit Service ID in Apple Developer
                // 2. Associate it with your App ID
                // 3. Generate a JWT token for authentication
                let kitService = WeatherKit.WeatherService.shared
                let weather = try await kitService.weather(for: location)
                let current = weather.currentWeather
                
                // Get temperature in Fahrenheit
                let tempValue = current.temperature
                let tempInCelsius = tempValue.value
                // Convert to Fahrenheit
                let tempInFahrenheit = (tempInCelsius * 9/5) + 32
                let temp = Int(tempInFahrenheit)
                temperature = "\(temp)°F"
                
                // Get condition description
                condition = current.condition.description
                
                // Get today's temperature range from daily forecast
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                
                // Find today's forecast
                for dayForecast in weather.dailyForecast.forecast {
                    if calendar.isDate(dayForecast.date, inSameDayAs: today) {
                        let lowCelsius = dayForecast.lowTemperature.value
                        let highCelsius = dayForecast.highTemperature.value
                        // Convert to Fahrenheit
                        let low = Int((lowCelsius * 9/5) + 32)
                        let high = Int((highCelsius * 9/5) + 32)
                        temperatureRange = "\(low)°-\(high)°F"
                        isLoading = false
                        return
                    }
                }
                
                // Fallback if today's forecast not found
                temperatureRange = "\(temp)°F"
                isLoading = false
            } catch {
                // Log error but keep trying WeatherKit
                if let nsError = error as NSError? {
                    let errorDomain = nsError.domain
                    let errorCode = nsError.code
                    
                    print("WeatherKit error: \(error.localizedDescription)")
                    print("WeatherKit error domain: \(errorDomain), code: \(errorCode)")
                    
                    // If JWT authentication error, provide helpful message
                    if errorDomain.contains("WDSJWTAuthenticator") || 
                       errorDomain.contains("WeatherDaemon") ||
                       errorCode == 2 {
                        print("⚠️ WeatherKit JWT authentication error.")
                        print("⚠️ To fix: Configure WeatherKit Service ID in Apple Developer portal")
                        print("⚠️ 1. Go to developer.apple.com")
                        print("⚠️ 2. Create a WeatherKit Service ID")
                        print("⚠️ 3. Associate it with your App ID")
                        print("⚠️ 4. Generate JWT token")
                    }
                } else {
                    print("WeatherKit error: \(error.localizedDescription)")
                }
                
                // Keep loading state but don't update weather data
                // This ensures the UI shows loading/error state
                isLoading = false
            }
        } else {
            print("WeatherKit requires iOS 16.0 or later")
            isLoading = false
        }
        #else
        print("WeatherKit not available")
        isLoading = false
        #endif
    }
    
}

extension WeatherService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        Task { @MainActor in
            await fetchWeatherWithWeatherKit(for: location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        Task { @MainActor in
            isLoading = false
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            Task { @MainActor in
                isLoading = false
            }
        }
    }
}

