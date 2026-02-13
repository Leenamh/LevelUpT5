//
//  DisableSwipeBack.swift
//  Bashkah
//
//  Created by leena almusharraf on 10/02/2026.
//


import SwiftUI

struct DisableSwipeBack: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DisableSwipeBackController())
    }
}

struct DisableSwipeBackController: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            controller
                .navigationController?
                .interactivePopGestureRecognizer?
                .isEnabled = false
        }
        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {}
}

extension View {
    func disableSwipeBack() -> some View {
        modifier(DisableSwipeBack())
    }
}
