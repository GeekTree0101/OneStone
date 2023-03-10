//
//  NavigationLink.swift
//  LiveViewNative
//
//  Created by Shadowfacts on 6/13/22.
//

import SwiftUI
import Combine

struct NavigationLink<R: CustomRegistry>: View {
    @ObservedElement private var element: ElementNode
    private let context: LiveContext<R>
    @EnvironmentObject private var navCoordinator: NavigationCoordinator
    @State private var doNavigationCancellable: AnyCancellable?
    
    init(element: ElementNode, context: LiveContext<R>) {
        self.context = context
    }
    
    @ViewBuilder
    public var body: some View {
        if let linkOpts = LinkOptions(element: element),
           context.coordinator.config.navigationMode.supportsLinkState(linkOpts.state) {
            SwiftUI.ZStack {
                SwiftUI.Button {
                    activateNavigationLink()
                } label: {
                    context.buildChildren(of: element)
                }
                .disabled(element.attribute(named: "disabled") != nil)
            }
        } else {
            // if there are no link options, or the coordinator doesn't support the required navigation, we don't show anything
        }
    }
    
    private func activateNavigationLink() {
        guard let linkOpts = LinkOptions(element: element) else {
            return
        }
        
        let dest = URL(string: linkOpts.href, relativeTo: context.url)!
        
        switch linkOpts.state {
        case .replace:
            navCoordinator.navigationPath[navCoordinator.navigationPath.count - 1] = dest
            Task {
                await context.coordinator.navigateTo(url: dest, replace: true)
            }
            
        case .push:
            func doPushNavigation() {
                navCoordinator.navigationPath.append(dest)
            }
            
            Task {
                await context.coordinator.navigateTo(url: dest, replace: false)
            }
            // TODO: when this happens, swiftui warns that publishing changes from within a view update is not allowed
            // even though this is happening in a button action, not sure why
            doPushNavigation()
            return
        }
    }
    
}

struct LinkOptions {
    let kind: LinkKind
    let state: LinkState
    let href: String
    
    init?(element: ElementNode) {
        guard let kindStr = element.attributeValue(for: "data-phx-link"),
              let kind = LinkKind(rawValue: kindStr),
              let stateStr = element.attributeValue(for: "data-phx-link-state"),
              let state = LinkState(rawValue: stateStr) else {
            return nil
        }
        self.kind = kind
        self.state = state
        self.href = element.attributeValue(for: "data-phx-href")!
    }
}

enum LinkKind: String {
    case redirect
}

enum LinkState: String {
    case push
    case replace
}

extension LiveViewConfiguration.NavigationMode {
    func supportsLinkState(_ state: LinkState) -> Bool {
        switch self {
        case .disabled:
            return false
        case .replaceOnly:
            return state == .replace
        case .enabled:
            return true
        }
    }
}
