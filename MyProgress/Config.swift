//  Config.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import Foundation

/**
 define discreet deployment environments, I'd say these 3 are a minimum
 (have you noticed I really think enums are cool!)
 */
enum Environment {
    /// For development, target local services only; "you break, you buy"
    case dev
    /// A stable server config, for integration testing;
    /// ideally, once test cycle complete, could be promoted directly to production
    case staging
    /// the customer-facing (revenue-generating, rock-solid service
    case prod
}

/**
 A simple mechanism to store / access config entries that differ based on targeted deployment environment.
 
 */
struct Config {
    
    // MARK: - Class-level Properties

    /// change this before build
    static var current: Environment = .staging
    
    /**
     Provide definitions for config values per each environment
     
     - Returns: the current Config struct
     */
    static var env: Config {
        switch current {
        case .dev:
            // Note: if one wishes to spin up a local api service (on http: rather than https:),
            // will need to modify Info.plist to include:
            /*
             <key>NSAppTransportSecurity</key>
             <dict>
             <key>NSAllowsArbitraryLoads</key>
             <true/>
             </dict>
             */
            // this workaround is not advised in production apps, nor allowed if deployed via iTunes
            return Config(displayName: "Development",
                          serverUrl: "http://localhost:8080/api/",
                          authHeaderKey: "Authentication-Info")
        case .staging:
            // BTW, this is a free-tier Heroku service;  it "sleeps" after 30 mins of inactivity
            return Config(displayName: "Staging",
                          serverUrl: "https://inspire-idaho-vapor-api.herokuapp.com/api/",
                          authHeaderKey: "Authentication-Info")
        case .prod:
            return Config(displayName: "Production",
                          serverUrl: "https:/to-be-determined.inspireidaho.com",
                          authHeaderKey: "X-Auth")
        }
    }
    
    // MARK: - Instance Properties

    /// provided in case we want to display to user
    let displayName: String
    
    /// the target api server URL will certainly differ based on environment
    let serverUrl: String
    
    /// huh, apparently some webservers return headers with different case keys
    let authHeaderKey: String
}




