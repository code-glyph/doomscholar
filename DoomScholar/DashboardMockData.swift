//
//  DashboardMockData 2.swift
//  DoomScholar
//
//  Created by Matthew Pun on 2/27/26.
//


import Foundation

enum DashboardMockData {
    static let courses: [DashboardCourse] = [
        .init(name: "Algorithms", code: "CS 2510", instructor: "Prof. Lin"),
        .init(name: "Linear Algebra", code: "MATH 21", instructor: "Prof. Patel"),
        .init(name: "Physics I", code: "PHYS 211", instructor: "Prof. Nguyen")
    ]

    static let appLinks: [DashboardAppLink] = [
        .init(title: "Instagram", url: "https://www.instagram.com", systemIcon: "camera"),
        .init(title: "Reddit", url: "https://www.reddit.com", systemIcon: "bubble.left.and.bubble.right"),
        .init(title: "TikTok", url: "https://www.tiktok.com", systemIcon: "play.square"),
        .init(title: "Facebook", url: "https://www.facebook.com", systemIcon: "person.2")
    ]
}