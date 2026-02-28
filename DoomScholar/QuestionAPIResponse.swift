//
//  QuestionAPIResponse.swift
//  DoomScholar
//
//  Created by Ajay Narayanan on 2/27/26.
//


// MARK: - API models

struct QuestionAPIResponse: Decodable {
    let id: String
    let topic: String
    let hint: String
    let answer: String
    let mcq: MCQ

    struct MCQ: Decodable {
        let question: String
        let options: [String]
        let correct_index: Int
    }
}

extension QuizQuestion {
    static func fromAPI(_ api: QuestionAPIResponse) -> QuizQuestion {
        QuizQuestion(
            prompt: api.mcq.question,
            choices: api.mcq.options,
            correctIndex: api.mcq.correct_index,
            explanation: api.answer
        )
    }
}
