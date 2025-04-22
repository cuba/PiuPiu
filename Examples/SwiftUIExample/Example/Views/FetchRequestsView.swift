//
//  ParallelRequestsView.swift
//  Example
//
//  Created by Jacob Sikorski on 2025-04-22.
//

import SwiftUI
import PiuPiu

struct FetchRequestsView: View {
  enum FetchType: Int, Hashable, CaseIterable {
    case series
    case parallel
    
    var label: String {
      switch self {
      case .series: String(localized: "Series")
      case .parallel: String(localized: "Parallel")
      }
    }
  }
  
  // Always hold a strong reference to the dispatcher
  private let dispatcher = URLRequestDispatcher(
    session: URLSession(
      configuration: URLSessionConfiguration.ephemeral
    )
  )
  
  private let sampleCount = 100
  @AppStorage("fetchType") private var fetchType: FetchType = .series
  @State private var posts: [(id: Int, post: String?)] = []
  @State private var fetchTask: Task<Void, Never>?
  @State private var error: Error?
  
  var body: some View {
    List {
      Section {
        Picker(selection: $fetchType) {
          ForEach(FetchType.allCases, id: \.self) { fetchType in
            Text(fetchType.label)
          }
        } label: {
          Text("Fetch type")
        }

        Button(
          "Fetch \(sampleCount) posts in \(fetchType.label)",
          systemImage: "arrow.down.circle",
          action: fetchPosts
        )
      } header: {
        Text("Configuration")
      }
      
      if posts.count > 0 {
        Section {
          VStack {
            HStack {
              Text("\(posts.count) fetched")
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
              Text("\(sampleCount)").font(.caption).foregroundStyle(.secondary)
            }
            ProgressView(
              value: Double(posts.count),
              total: Double(sampleCount)
            )
          }
          
          ForEach(posts, id: \.id) { post in
            Text(post.post ?? "Loading...")
          }
        } header: {
          Text("Posts")
        }
      }
    }
  }
  
  private func fetchPosts() {
    fetchTask = Task {
      do {
        switch fetchType {
        case .series:
          try await fetchPostsInSeries()
        case .parallel:
          try await fetchPostsInParallel()
        }
      } catch is CancellationError {
        // Do nothing
      } catch {
        self.error = error
      }
    }
  }
  
  private func fetchPostsInSeries() async throws {
    let sampleCount = self.sampleCount
    let ids = (1...sampleCount)
    posts = []
    
    // For a series requests you can chain the requests
    // by putting them all in a single Task.
    // No need to manage order as the requests will occur in sequence
    for id in ids {
      try Task.checkCancellation()
      let result = try await self.fetchPost(forId: id)
      posts.append((id, result.body))
    }
  }
  
  private func fetchPostsInParallel() async throws {
    let sampleCount = self.sampleCount
    let ids = (1...sampleCount)
    posts = ids.map({ (id: $0, nil) })
    
    // For parallel requests, put each request in its own Task
    // But you will have to manage order yourself.
    try await ids.enumerated().parallelForEach { index, id in
      let result = try await self.fetchPost(forId: id)
      
      Task { @MainActor in
        posts[index] = (id, result.body)
      }
    }
  }
  
  private func fetchPost(forId id: Int) async throws -> HTTPResponse<String> {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!
    let request = URLRequest(url: url, method: .get)
    
    return try await dispatcher.data(from: request)
      // Log the response
      .log()
      // Ensure the response is an HTTP reponse
      .ensureHTTPResponse()
      // Ensure the response has a valid status code
      .ensureValidResponse()
      // Ensure the body (Data) is not empty
      .ensureBody()
      // Lets prettify the JSON
      .map { data -> Data in
        return try JSONSerialization.data(
          withJSONObject: JSONSerialization.jsonObject(with: data),
          options: .prettyPrinted
        )
      }
      // Change the body to a String value
      .ensureStringBody(encoding: .utf8)
  }
}

#Preview {
  FetchRequestsView()
}
