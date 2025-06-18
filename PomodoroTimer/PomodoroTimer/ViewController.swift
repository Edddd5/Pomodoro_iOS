//
//  ViewController.swift
//  PomodoroTimer2
//
//  Created by 장동혁 on 6/17/25.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var minPicker: UIPickerView!
    @IBOutlet weak var progressContainer: UIView!
    @IBOutlet weak var sessionNameTextField: UITextField!
    @IBOutlet weak var restTimeTextField: UITextField!
    @IBOutlet weak var focusButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var forMinLabel: UILabel!
    
    let pickerData = ["0.25"] + Array(stride(from: 5, through: 60, by: 5)).map { "\($0)"}
    let maxMinutes: CGFloat = 60

    private var backgroundLayer = CAShapeLayer()
    private var progressLayer = CAShapeLayer()
    private var timer: Timer?
    private var remainingSeconds: Int = 0
    private var totalSeconds: Int = 0
    private var isFocusing = false
    private var isPaused = false
    private var isResting = false
    private var restSeconds: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        minPicker.dataSource = self
        minPicker.delegate = self
        sessionNameTextField.delegate = self

        sessionNameTextField.attributedPlaceholder = NSAttributedString(
            string: "😀 세션의 이름을 정해주세요.",
            attributes: [.foregroundColor: UIColor.white]
        )
        
        restTimeTextField.attributedPlaceholder = NSAttributedString(
            string: "🔋 쉬는 시간(분)",
            attributes: [.foregroundColor: UIColor.white]
        )

        progressContainer.backgroundColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        setupCircleProgress()

        if let defaultRow = pickerData.firstIndex(of: "25") {
            minPicker.selectRow(defaultRow, inComponent: 0, animated: false)
        }

        updateProgress(for: 25, animated: false)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        stopButton.isHidden = true
        endButton.isHidden = true
        timerLabel.isHidden = true
        forMinLabel.isHidden = false

    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func focusButtonTapped(_ sender: UIButton) {
        startFocusSession()
    }

    @IBAction func stopButtonTapped(_ sender: UIButton) {
        if isPaused {
            resumeFocusSession()
        } else {
            pausedFocusSession()
        }
    }

    @IBAction func endButtonTapped(_ sender: UIButton) {
        saveSessionStats(focusSeconds: totalSeconds, restSeconds: restSeconds)
        endFocusSession()
    }
    
    private func startFocusSession() {
        let minutes = getSelectedMinutes()
        if pickerData[minPicker.selectedRow(inComponent: 0)] == "0.25" {
            totalSeconds = 15
        } else {
            totalSeconds = minutes * 60
        }
        remainingSeconds = totalSeconds
        isFocusing = true
        isPaused = false

        focusButton.isHidden = true
        stopButton.isHidden = false
        endButton.isHidden = false

        stopButton.setTitle("STOP", for: .normal)

        minPicker.isHidden = true
        timerLabel.isHidden = false
        forMinLabel.isHidden = true
        updateTimerLabel()

        sessionNameTextField.isUserInteractionEnabled = false
        updateProgress(for: minutes, animated: false)

        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
    }

    private func startRestSession() {
        guard let restText = restTimeTextField.text else {
            stopFocusSession()
            return
        }
        if restText == "0.25" {
            restSeconds = 15
        } else if let restMin = Int(restText), restMin > 0 {
            restSeconds = restMin * 60
        } else {
            stopFocusSession()
            return
        }
        remainingSeconds = restSeconds
        isResting = true

        progressLayer.strokeColor = UIColor(red: 76/255.0, green: 175/255.0, blue: 80/255.0, alpha: 1.0).cgColor

        timerLabel.isHidden = false
        forMinLabel.isHidden = true
        updateTimerLabel()

        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
    }

    private func updateTimerLabel() {
        let min = remainingSeconds / 60
        let sec = remainingSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", min, sec)
    }

    private func pausedFocusSession() {
        timer?.invalidate()
        timer = nil
        isPaused = true
        stopButton.setTitle("START", for: .normal)
    }

    private func resumeFocusSession() {
        isPaused = false
        stopButton.setTitle("STOP", for: .normal)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
    }

    private func stopFocusSession() {
        timer?.invalidate()
        timer = nil
        isFocusing = false
        isPaused = false
        isResting = false

        focusButton.isHidden = false
        stopButton.isHidden = true
        endButton.isHidden = true

        minPicker.isHidden = false
        timerLabel.isHidden = true
        forMinLabel.isHidden = false

        minPicker.isUserInteractionEnabled = true
        sessionNameTextField.isUserInteractionEnabled = true
        restTimeTextField.isUserInteractionEnabled = true

        updateProgress(for: getSelectedMinutes(), animated: true)
    }

    private func endFocusSession() {
        timer?.invalidate()
        timer = nil
        isFocusing = false
        isPaused = false
        isResting = false

        focusButton.isHidden = false
        stopButton.isHidden = true
        endButton.isHidden = true
        forMinLabel.isHidden = false

        minPicker.isHidden = false
        timerLabel.isHidden = true

        minPicker.isUserInteractionEnabled = true
        sessionNameTextField.isUserInteractionEnabled = true
        restTimeTextField.isUserInteractionEnabled = true

        updateProgress(for: getSelectedMinutes(), animated: true)
    }

    @objc private func timerTick() {
        guard remainingSeconds > 0 else {
            timer?.invalidate()
            if isFocusing {
                startRestSession()
            } else if isResting {
                progressLayer.strokeColor = UIColor(red: 209/255.0, green: 59/255.0, blue: 123/255.0, alpha: 1.0).cgColor
                isResting = false
                isFocusing = false
                saveSessionStats(focusSeconds: totalSeconds, restSeconds: restSeconds)
                endFocusSession()
            }
            return
        }
        remainingSeconds -= 1

        updateTimerLabel()

        if isResting {
        // ★ 휴식 시간에는 0 → 1로 차오르게
            let progress = CGFloat(restSeconds - remainingSeconds) / CGFloat(restSeconds)
            updateProgress(progress: progress, animated: true)
        } else {
            // 집중 시간에는 기존처럼 1 → 0으로 줄어들게
            let progress = CGFloat(remainingSeconds) / CGFloat(totalSeconds)
            updateProgress(progress: progress, animated: true)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    private func setupCircleProgress() {
        backgroundLayer.removeFromSuperlayer()
        progressLayer.removeFromSuperlayer()

        let center = CGPoint(x: progressContainer.bounds.midX, y: progressContainer.bounds.midY)
        let radius = min(progressContainer.bounds.width, progressContainer.bounds.height) / 2 - 10

        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi

        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

        backgroundLayer.path = circlePath.cgPath
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.strokeColor = UIColor.white.cgColor
        backgroundLayer.lineWidth = 8
        backgroundLayer.lineCap = .round
        progressContainer.layer.addSublayer(backgroundLayer)

        progressLayer.path = circlePath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor(red: 209/255.0, green: 59/255.0, blue: 123/255.0, alpha: 1.0).cgColor
        progressLayer.lineWidth = 8
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        progressContainer.layer.addSublayer(progressLayer)
    }

    private func updateProgress(for minutes: Int, animated: Bool = true) {
        let progress = min(CGFloat(minutes) / maxMinutes, 1.0)
        updateProgress(progress: progress, animated: animated)
    }

    private func updateProgress(progress: CGFloat, animated: Bool = true) {
        progressLayer.removeAllAnimations()
        let clamped = max(0, min(progress, 1.0))
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.presentation()?.strokeEnd ?? progressLayer.strokeEnd
            animation.toValue = clamped
            animation.duration = 0.5
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            progressLayer.add(animation, forKey: "progressAnimation")
            DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration) {
                self.progressLayer.strokeEnd = clamped
                self.progressLayer.removeAllAnimations()
            }
        } else {
            progressLayer.strokeEnd = clamped
        }
    }

    func numberOfComponents(in minPicker: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ minPicker: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }

    func pickerView(_ minPicker: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: pickerData[row], attributes: [.foregroundColor: UIColor.white])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedMinutes = Int(pickerData[row]) ?? 25
        updateProgress(for: selectedMinutes, animated: true)
    }

    func getSelectedMinutes() -> Int {
        let selectedRow = minPicker.selectedRow(inComponent: 0)
        let value = pickerData[selectedRow]
        if value == "0.25" {
            return 0
        }
        return Int(pickerData[selectedRow]) ?? 25
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func saveSessionStats(focusSeconds: Int, restSeconds: Int) {
        let prevFocus = UserDefaults.standard.integer(forKey: "totalFocusSeconds")
        let prevRest = UserDefaults.standard.integer(forKey: "totalRestSeconds")
        UserDefaults.standard.set(prevFocus + focusSeconds, forKey: "totalFocusSeconds")
        UserDefaults.standard.set(prevRest + restSeconds, forKey: "totalRestSeconds")
    }
}
