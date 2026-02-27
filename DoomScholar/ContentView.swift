//
//  ContentView.swift
//  DoomScholar
//
//  Created by Ajay Narayanan on 2/27/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DashboardView()
            .appTheme(AppTheme()) // swap theme here later
    }
}

#Preview {
    ContentView()
}
