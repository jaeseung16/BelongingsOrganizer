//
//  AdSupportModifier.swift
//  Belongings Organizer with Ads (iOS)
//
//  Created by Jae Seung Lee on 9/17/26.
//

#if ADS
import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds

extension View {
    // Compiled into the ads target only, so ContentView needs a single #if ADS site.
    func adSupport() -> some View {
        modifier(AdSupportModifier())
    }
}

struct AdSupportModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                BannerAd()
                    .frame(height: 50)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                ATTrackingManager.requestTrackingAuthorization { status in
                    MobileAds.shared.start(completionHandler: nil)

                }
            }
    }
}
#endif
