//
//  LiveView.swift
//  LiveViewTest
//
//  Created by Brian Cardarella on 4/28/21.
//

import Foundation
import SwiftUI
import Introspect

/// The SwiftUI root view for a Phoenix LiveView.
///
/// The `LiveView` attempts to connect immediately when it appears.
///
/// While in states other than ``LiveViewCoordinator/State-swift.enum/connected``, this view only provides a basic text description of the state. The loading view can be customized with a custom registry and the ``CustomRegistry/loadingView(for:state:)-vg2v`` method.
///
/// ## Topics
/// ### Creating a LiveView
/// - ``init(coordinator:)``
/// ### Supporting Types
/// - ``body``
/// ### See Also
/// - ``LiveViewModel``
public struct LiveView<R: CustomRegistry>: View {
    private let coordinator: LiveViewCoordinator<R>
    @State private var hasAppeared = false
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @State private var hasSetupNavigationControllerDelegate = false
    
    /// Creates a new LiveView attached to the given coordinator.
    ///
    /// - Note: Changing coordinators after the `LiveView` is setup and connected is forbidden.
    public init(coordinator: LiveViewCoordinator<R>) {
        self.coordinator = coordinator
    }

    public var body: some View {
      NavStackEntryView(coordinator: coordinator, url: coordinator.initialURL)
        .onAppear {
          if !hasAppeared {
              hasAppeared = true
              Task {
                  await coordinator.connect()
              }
          }
        }
    }
}
