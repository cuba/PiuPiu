//
//  UploadsView.swift
//  Example
//
//  Created by Jacob Sikorski on 2025-04-22.
//

import SwiftUI
import SwiftData

struct ContentView: View {
  var body: some View {
    NavigationSplitView {
      List {
        Section {
          NavigationLink {
            FetchRequestsView()
          } label: {
            HStack(spacing: 16) {
              Image(systemName: "square.and.arrow.down.on.square")
                .foregroundStyle(.tint)
              VStack(alignment: .leading) {
                Text("Request example")
                Text("Perform sample API requests in parallel or series")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
          NavigationLink {
            UploadsView()
          } label: {
            HStack(spacing: 16) {
              Image(systemName: "paperclip")
                .foregroundStyle(.tint)
              VStack(alignment: .leading) {
                Text("Upload & download example")
                Text("Perform sample upload and download requests")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
        } header: {
          Text("Examples")
        }
      }
    } detail: {
      Text("Select an item")
    }
  }
}

#Preview {
  ContentView()
}
