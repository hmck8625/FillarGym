//
//  ContentView.swift
//  FillarGym
//
//  Created by 浜崎大輔 on 2025/07/05.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabBarView()
            .environment(\.managedObjectContext, viewContext)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
