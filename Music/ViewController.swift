
import UIKit
import AVFoundation
import KDCircularProgress
import MediaPlayer

var mediaItems = [MPMediaItem]()
var soundPlayer:AVAudioPlayer?

class ViewController: UIViewController, AVAudioPlayerDelegate {

    
    
    let player = MPMusicPlayerController.systemMusicPlayer()
    var flag = 0
    var playFlag = false
    var playItem = -1
    var timer = Timer()
    
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var progressView: KDCircularProgress!
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var albumName: UILabel!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var seekSlider: UISlider!
    
    
//************************************************************************************************************
//       View Did Load Method
//************************************************************************************************************

    override func viewDidLoad() {
        super.viewDidLoad()
        //LockScreen Media control registry
        if UIApplication.shared.responds(to: #selector(UIApplication.beginReceivingRemoteControlEvents)){
            UIApplication.shared.beginReceivingRemoteControlEvents()
            UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            })
        }
        
        progressView.progressThickness = 0.15
        progressView.trackThickness = 0.1
        progressView.progressColors = [UIColor(red: 240.0/255.0, green: 145/255.0, blue: 145/255.0, alpha: 1)]
        progressView.trackColor = UIColor(red: 239.0/255.0, green: 223/255.0, blue: 225/255.0, alpha: 1)
        
        bottomView.backgroundColor = UIColor.lightGray
        
        seekSlider.isContinuous = false
        seekSlider.minimumValue = 0.0

        mediaItems = MPMediaQuery.songs().items!
        let mediaCollection = MPMediaItemCollection(items: mediaItems)
        player.setQueue(with: mediaCollection)
        if playFlag == true{
            playFlag = false
            player.nowPlayingItem = mediaItems[playItem]
            flag = 1
            avaudio()
            play.setImage(UIImage(named: "pause"), for: UIControlState())
        }
        else{
            avaudio()
        }
        artwork.layer.cornerRadius = 80
        artwork.layer.masksToBounds = false
        artwork.clipsToBounds = true
        
        let displayLink:CADisplayLink = CADisplayLink(target: self, selector: #selector(ViewController.updateMeters))
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }//For playing audio in background
        
    }

//************************************************************************************************************
//       Play, pause, rewind, forward, reset, seek functionality
//************************************************************************************************************
    
    @IBAction func playPausePressed(_ sender: AnyObject) {
        playPausedPress()
    }
    
    
    @IBAction func forwardPressed(_ sender: AnyObject) {
        forwardPressed()
    }
    
    @IBAction func rewindPressed(_ sender: AnyObject) {
        rewindPressed()
    }
    
    @IBAction func resetPressed(_ sender: AnyObject) {
        resetPressed()
    }
    
    @IBAction func showList(_ sender: AnyObject) {
        performSegue(withIdentifier: "showList", sender: self)
    }
    
    @IBAction func sliderMoved(_ sender: Any) {
        sliderMoved()
    }
    
    func playPausedPress(){
        if flag == 0{
            flag = 1
            play.setImage(UIImage(named: "pause"), for: UIControlState())
            avaudio()
        }else{
            flag = 0
            timer.invalidate()
            play.setImage(UIImage(named: "play"), for: UIControlState())
            soundPlayer?.pause()
        }
    }
    
    func forwardPressed(){
        player.skipToNextItem()
        avaudio()
        updateAudioProgressView()
        soundPlayer?.isMeteringEnabled = true
    }
    
    func resetPressed(){
        soundPlayer?.pause()
        soundPlayer?.currentTime = 0
        if flag == 1{
            soundPlayer?.play()
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.updateAudioProgressView), userInfo: nil, repeats: true)
        }else{
            progressView.angle = 0
        }
    }
    
    func rewindPressed(){
        player.skipToPreviousItem()
        avaudio()
        updateAudioProgressView()
        soundPlayer?.isMeteringEnabled = true
    }

    func sliderMoved(){
        // if the track was playing store true, so we can restart playing after changing the track position
        var wasPlaying : Bool = false
        if playFlag == true {
            soundPlayer?.pause()
            wasPlaying = true
        }
        soundPlayer?.currentTime = TimeInterval(seekSlider.value)
        updateProgress()
        // starts playing track again it it had been playing
        if (wasPlaying == true) {
            soundPlayer?.play()
            wasPlaying = false
        }
    }

    func updateProgress() {
        let progress = (soundPlayer?.currentTime)! / (soundPlayer?.duration)!
        seekSlider.setValue(Float(progress), animated: false)
        let current = progress * 360
        progressView.angle = Double(current)
    }
    
    
//************************************************************************************************************
//
//************************************************************************************************************

    func avaudio(){
        if player.nowPlayingItem != nil{
            songName.text = player.nowPlayingItem?.title!.uppercased()
            albumName.text = player.nowPlayingItem?.albumTitle!.uppercased()
            let current = player.nowPlayingItem
            let url = current?.value(forProperty: MPMediaItemPropertyAssetURL) as? URL
            let item = AVPlayerItem(url: url!)
            let info = item.asset.metadata
            artwork.image = UIImage(named: "placeholder")
            for item in info {
                if item.commonKey  == "artwork" {
                    artwork.image = UIImage(data: item.value as! Data)
                }
            }
            
            do{
                soundPlayer = try AVAudioPlayer(contentsOf: url!)
                soundPlayer?.delegate = self
                soundPlayer?.prepareToPlay()
                soundPlayer?.volume = 1.0
                if flag == 1{
                    soundPlayer?.play()
                    timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.updateAudioProgressView), userInfo: nil, repeats: true)
                    soundPlayer?.isMeteringEnabled = true
                }
            }catch let error as NSError{
                soundPlayer = nil
                songName.text = "\(error.localizedDescription)"
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyArtist : songName.text!,  MPMediaItemPropertyTitle : albumName.text!]

        }
        else{
            play.setImage(UIImage(named: "play"), for: UIControlState())
            play.isEnabled = false
            songName.text = ""
            albumName.text = ""
            artwork.image = nil
        }
    }
    
    
//************************************************************************************************************
//        Remote control methods
//************************************************************************************************************
    
    override func remoteControlReceived(with event: UIEvent?) {
        if event!.type == UIEventType.remoteControl{
            switch event!.subtype{
            case UIEventSubtype.remoteControlPlay:
                playPausedPress()
            case UIEventSubtype.remoteControlPause:
                playPausedPress()
            case UIEventSubtype.remoteControlNextTrack:
                forwardPressed()
            case UIEventSubtype.remoteControlPreviousTrack:
                rewindPressed()
            case UIEventSubtype.remoteControlBeginSeekingBackward: sliderMoved()
            case UIEventSubtype.remoteControlBeginSeekingForward: sliderMoved()
            case UIEventSubtype.remoteControlEndSeekingBackward: sliderMoved()
            case UIEventSubtype.remoteControlEndSeekingForward: sliderMoved()
            default:
                print("There is an issue with the control")
            }
        }
    }

    
//************************************************************************************************************
//
//************************************************************************************************************

    func updateAudioProgressView(){
        if (soundPlayer?.currentTime)! > (soundPlayer?.duration)! - 1{
            player.skipToNextItem()
            avaudio()
        }
        let current = (soundPlayer?.currentTime)!/(soundPlayer?.duration)! * 360
        progressView.angle = Double(current)
        seekSlider.maximumValue = Float((soundPlayer?.duration)!)
        UIView.animate(withDuration: 0.1, animations: {
            self.seekSlider.setValue(Float((soundPlayer?.currentTime)!), animated:true)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    func updateMeters() {
        soundPlayer?.updateMeters()
    }

}

