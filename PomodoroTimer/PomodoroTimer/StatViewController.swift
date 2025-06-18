//
//  StatViewController.swift
//  PomodoroTimer2
//
//  Created by 장동혁 on 6/18/25.
//

import UIKit

class StatsViewController: UIViewController {
    @IBOutlet weak var focusLabel: UILabel!
    @IBOutlet weak var restLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStats()
    }

    func updateStats() {
        let focus = UserDefaults.standard.integer(forKey: "totalFocusSeconds")
        let rest = UserDefaults.standard.integer(forKey: "totalRestSeconds")
        focusLabel.text = "집중 시간: \(focus / 60)분 \(focus % 60)초"
        restLabel.text = "휴식 시간: \(rest / 60)분 \(rest % 60)초"
        let total = focus + rest
        let score = total == 0 ? 0 : Int(Double(focus) / Double(total) * 100)
        scoreLabel.text = "집중도: \(score)%"
    }
}
