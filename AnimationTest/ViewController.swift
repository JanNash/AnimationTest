//
//  ViewController.swift
//  AnimationTest
//
//  Created by Jan Nash on 17.09.20.
//

import UIKit


class ViewController: UIViewController {
    private var progressBarContainer = ProgressBarContainer()
    private lazy var startButton: UIButton = {
        let button = UIButton()
        button.setTitle("Start animation", for: .normal)
        button.addTarget(progressBarContainer, action: #selector(ProgressBarContainer.startAnimator), for: .touchUpInside)
        button.backgroundColor = UIColor.blue
        return button
    }()
    
    private lazy var pauseButton: UIButton = {
        let button = UIButton()
        button.setTitle("Pause animation", for: .normal)
        button.addTarget(progressBarContainer, action: #selector(ProgressBarContainer.pauseAnimator), for: .touchUpInside)
        button.backgroundColor = UIColor.blue
        return button
    }()
    
    private lazy var stopButton: UIButton = {
        let button = UIButton()
        button.setTitle("Stop animation", for: .normal)
        button.addTarget(progressBarContainer, action: #selector(ProgressBarContainer.stopAnimator), for: .touchUpInside)
        button.backgroundColor = UIColor.blue
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(progressBarContainer)
        progressBarContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressBarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressBarContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150),
            progressBarContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            progressBarContainer.heightAnchor.constraint(equalToConstant: 60),
        ])
        
        view.addSubview(startButton)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: progressBarContainer.bottomAnchor, constant: 20),
            startButton.widthAnchor.constraint(equalTo: progressBarContainer.widthAnchor),
            startButton.heightAnchor.constraint(equalToConstant: 60),
        ])
        
        view.addSubview(pauseButton)
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pauseButton.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 20),
            pauseButton.widthAnchor.constraint(equalTo: progressBarContainer.widthAnchor),
            pauseButton.heightAnchor.constraint(equalToConstant: 60),
        ])
        
        view.addSubview(stopButton)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopButton.topAnchor.constraint(equalTo: pauseButton.bottomAnchor, constant: 20),
            stopButton.widthAnchor.constraint(equalTo: progressBarContainer.widthAnchor),
            stopButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
}


class ProgressBarContainer: UIView {
    required init?(coder: NSCoder) { fatalError() }
    init() {
        super.init(frame: .zero)
        backgroundColor = .green
        addSubview(progressBar)
        animator = createAnimator()
    }
    
    private var progressBar = ProgressBar()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        progressBar.frame = bounds.inset(by: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
        animator?.updateForLayoutChange()
    }
    
    private var animator: Animator<ProgressBar>?
    func createAnimator() -> Animator<ProgressBar> {
        let animator = Animator<ProgressBar>(duration: 10)
        animator.seekTo(progress: 0.5)
        animator.keyframes = Keyframes(for: progressBar, [
            (relStart: 0, relDuration: 0, { $0.setProgress(0) }),
            (relStart: 0, relDuration: 1, { $0.setProgress(1) })
        ])
        return animator
    }
    
    @objc func startAnimator() { animator?.play() }
    @objc func pauseAnimator() { animator?.pause() }
    @objc func stopAnimator() { animator?.stop() }
}


class ProgressBar: UIView {
    func setProgress(_ progress: CGFloat) {
        self.progress = progress
        upcomingView.frame.size.width = frame.width * progress
    }
    
    private var progress: CGFloat = 0
    
    var progressColor = UIColor.red { didSet { upcomingView.backgroundColor = progressColor } }
    
    required init?(coder: NSCoder) { fatalError() }
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .yellow
    }
    
    private lazy var upcomingView: UIView = {
        let view = UIView()
        view.backgroundColor = progressColor
        addSubview(view)
        return view
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        upcomingView.frame = bounds
        setProgress(progress)
    }
}
