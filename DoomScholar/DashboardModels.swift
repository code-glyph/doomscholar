import Foundation

struct DashboardCourse: Identifiable {
    let id = UUID()
    let name: String
    let code: String
    let instructor: String
}

struct DashboardAppLink: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let systemIcon: String
}
