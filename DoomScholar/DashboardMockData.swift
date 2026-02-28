//
//  DashboardMockData 2.swift
//  DoomScholar
//
//  Created by Matthew Pun on 2/27/26.
//


import Foundation

enum DashboardMockData {
    static let courses: [DashboardCourse] = [
        .init(name: "Programming and Computation II: Data Structures", code: "CMPSC 132", instructor: "Prof. Krishna Kambhampaty"),
        .init(name: "Introduction to Systems Programming", code: "CMPSC 311", instructor: "Prof. Sencun Zhu"),
        .init(name: "Programming for Engineers with MATLAB", code: "CMPSC 200", instructor: "Prof.  Brad Sottile")
    ]

    static let appLinks: [DashboardAppLink] = [
        .init(title: "Instagram", url: "https://www.instagram.com", systemIcon: "camera"),
        .init(title: "Reddit", url: "https://www.reddit.com", systemIcon: "bubble.left.and.bubble.right"),
        .init(title: "TikTok", url: "https://www.tiktok.com", systemIcon: "play.square"),
        .init(title: "Facebook", url: "https://www.facebook.com", systemIcon: "person.2")
    ]
}
