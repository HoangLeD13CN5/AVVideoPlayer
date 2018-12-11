//
//  ViewController.swift
//  AVPlayerLayerVideo
//
//  Created by Hoang Le on 12/11/18.
//  Copyright © 2018 Hoang Le. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Foundation

class ViewController: UIViewController {
    @IBOutlet weak var btnPlayOrPause: UIButton!
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var contanerView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var sliderSeekVideo: UISlider!
    
    @IBOutlet weak var sliderVolume: UISlider!
    @IBOutlet weak var segmentedPlaySpeed: UISegmentedControl!
    
    @IBOutlet weak var zoomView: UIView!
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    let videoUrl: URL = URL(string: "http://clips.vorwaerts-gmbh.de/VfE_html5.mp4")!
    
    var speedVideo:Float = 1.0{
        didSet{
            self.changeSpeedVideo()
        }
    }
    var isPlayVideo = false {
        didSet{
            self.playOrPauseVideo()
        }
    }
    @IBOutlet weak var lblTimeRange: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        setupUI()
        initPlayer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.isPlayVideo = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.isPlayVideo = false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    @IBAction func changeLocationZoom(_ recognizer:UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view {
            view.center = CGPoint(x:view.center.x + translation.x,
                                  y:view.center.y + translation.y)
        }
        recognizer.setTranslation(CGPoint.zero, in: self.view)
    }
    
    @IBAction func openFrame(_ sender: Any) {
        if self.zoomView.isHidden {
            self.isPlayVideo = true
            self.zoomView.isHidden = false
        }else {
             self.zoomView.isHidden = true
        }
    }
    @IBAction func zoom(_ sender: Any) {
        if !self.zoomView.isHidden {
            if self.scrollView.zoomScale == self.scrollView.minimumZoomScale {
                let point = self.zoomView.frame.origin
                let convertedTap = self.view.convert(point, to: self.playerView)
                self.scrollView.zoom(to: CGRect(x: convertedTap.x, y: convertedTap.y, width: self.zoomView.frame.width, height: self.zoomView.frame.height), animated: true)
            }else {
                self.scrollView.setZoomScale(CGFloat(1), animated: true)
            }
        }
    }
    
    @IBAction func speedChange(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.speedVideo = 0.5
            break
        case 2:
             self.speedVideo = 2.0
            break
        default:
            self.speedVideo = 1.0
            break
        }
    }
    
    @IBAction func seekChange(_ sender: UISlider) {
        let seconds : Int64 = Int64(sender.value)
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        self.player!.seek(to: targetTime)
    }
    
    @IBAction func volumeChange(_ sender: UISlider) {
        self.player?.volume = sender.value
    }
    
    func setupUI(){
        self.scrollView.delegate = self
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 5.0
        self.zoomView.isHidden = true
    }
    
    @IBAction func tapPlayOrPauseVideo(_ sender: Any) {
        self.isPlayVideo = !self.isPlayVideo
    }
    
}

extension ViewController:UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.playerView
    }
}

// setup Player
private extension ViewController {
    func initPlayer(){
        playerItem = AVPlayerItem(url: videoUrl)
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = self.playerView.bounds
        self.playerView.layer.addSublayer(playerLayer!)
        // setup video loop
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: .main) {[weak self] _  in
            self?.player?.seek(to: CMTime.zero)
            self?.player?.play()
        }
       
        // set value Seek UISlide
        self.sliderSeekVideo.minimumValue = 0
        let duration:CMTime = playerItem!.asset.duration
        self.sliderSeekVideo.maximumValue = Float(CMTimeGetSeconds(duration))
        self.sliderSeekVideo.isContinuous = true
        self.lblTimeRange.text = "0.0/\(round(Float(CMTimeGetSeconds(duration))))"
        // set value Volume UISlide
        self.sliderVolume.minimumValue = 0
        self.sliderVolume.maximumValue = 1.0
        self.player?.volume = 1.0
        self.sliderVolume.value = 1.0
        
        // listen KVO when time video change
        self.player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1,timescale: 100), queue: DispatchQueue.main) { [unowned self] time in
            let endTime = CMTimeConvertScale(self.playerItem!.asset.duration,
                                             timescale: time.timescale,
                                             method: .roundHalfAwayFromZero)
            let currentTimeF: Float = (Float)(CMTimeGetSeconds(time))
            let endTimeF: Float = (Float)(CMTimeGetSeconds(endTime))
            // update time
            self.sliderSeekVideo.value = currentTimeF
            self.lblTimeRange.text = "\(round(currentTimeF))/\(round(endTimeF))"
        }
        self.segmentedPlaySpeed.selectedSegmentIndex = 1
    }
    
    func playOrPauseVideo(){
        if self.isPlayVideo {
            self.btnPlayOrPause.setImage(UIImage(named: "play"), for: .normal)
            self.player?.pause()
        }else {
            self.zoomView.isHidden = true
            self.btnPlayOrPause.setImage(UIImage(named: "pause"), for: .normal)
            self.player?.play()
        }
    }
    
    func changeSpeedVideo(){
        self.player?.rate = self.speedVideo
        self.isPlayVideo = true
    }
}
