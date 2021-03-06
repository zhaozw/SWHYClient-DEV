//
//  AudioRecorder.swift
//  SWHYClient_DEV
//
//  Created by sunny on 7/31/16.
//  Copyright © 2016 DY-INFO. All rights reserved.
// new branch

import Foundation
import AVFoundation
import AudioKit
//protocol AudioRecorderViewControllerDelegate: class {
//   func audioRecorderViewControllerDismissed(withFileURL fileURL: NSURL?)
//}

//AVAudioRecorderDelegate

@objc(AudioRecorder_bak2) class AudioRecorder_bak2: UIViewController,AVAudioPlayerDelegate{
    
    
    //@IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var btn_Record: MKButton!
    @IBOutlet weak var btn_Play: MKButton!
    @IBOutlet weak var btn_Save: UIButton!
    @IBOutlet weak var btn_pause: UIButton!
    
    @IBOutlet var audioInputPlot: EZAudioPlot!
    
    var timeTimer: NSTimer?
    var timeinterval:NSTimeInterval?
    //var milliseconds: Int = 0
    
    var recorder: AVAudioRecorder?
    var player: AVAudioPlayer?
    var outputURL: NSURL = NSURL()
    var audioTmpPath:String = ""
    var audioPath:String = ""
    var audioTmpFilePath:String  = ""
    var audioFilePath:String  = ""
    //var recording:String = ""
    var audioTmpFileName:String = ""
    var audioFileName:String = ""
    
    var tmptitle:String = ""
    var tmpdesc:String = ""
    
    var recordercolor:UIColor?
    
    var mic: AKMicrophone!
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!
    
    
    let noteFrequencies = [16.35,17.32,18.35,19.45,20.6,21.83,23.12,24.5,25.96,27.5,29.14,30.87]
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?){
        //let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        // let outputPath = documentsPath.stringByAppendingPathComponent("\(NSUUID().UUIDString).m4a")
        //outputURL = NSURL(fileURLWithPath: outputPath)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }
    
    convenience init() {
        self.init(nibName: "AudioRecorder", bundle: nil)
        // self.init
        //self.init(nibName: "LaunchScreen", bundle: nil)
        
    }
    
    required init(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.title = Message.shared.curMenuItem.name
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        DaiFileManager.document["/Audio_Tmp/"].delete()
        
        self.audioTmpPath = DaiFileManager.document["/Audio_Tmp/"].path
        self.audioPath = DaiFileManager.document["/Audio/"].path
        
        btn_Record.userInteractionEnabled = true
        self.recordercolor = btn_Record.backgroundColor
        
        mic = AKMicrophone()
        tracker = AKFrequencyTracker.init(mic)
        silence = AKBooster(tracker, gain: 0)
        
        //初始化record-----------------------------------------
        let dateFormatter:NSDateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "yyyyMMddHHmmss";
        let tmpdate = "\(dateFormatter.stringFromDate(NSDate()))"
        //LinearPCM
        self.audioTmpFileName = tmpdate+".wav"
        self.audioFileName = tmpdate+".mp3"
        
        self.audioTmpFilePath = self.audioTmpPath + self.audioTmpFileName        
        self.audioFilePath = self.audioPath + self.audioFileName
        
        outputURL = NSURL(fileURLWithPath: audioTmpFilePath)
        
        let settings = [AVFormatIDKey: NSNumber(unsignedInt: kAudioFormatLinearPCM),//编码格式
            AVSampleRateKey: NSNumber(integer: 44100), //声音采样率
            AVNumberOfChannelsKey: NSNumber(integer: 2),////采集音轨
            AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.High.rawValue))//音量
        ]
        try! recorder = AVAudioRecorder(URL: outputURL, settings: settings)
        //recorder.delegate = self
        
    }
    func setupPlot() {
        print(audioInputPlot.frame)
        print(audioInputPlot.bounds)
        //
        //let plot = AKNodeOutputPlot(mic, frame: audioInputPlot.bounds)
        let plot = AKNodeOutputPlot(mic, frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 100))
        plot.plotType = .Rolling
        plot.shouldFill = true
        
        plot.shouldMirror = true
        plot.color = UIColor.grayColor()
        //plot.frame.width = audioInputPlot.frame.width
        
        print(plot.frame)
        
        //audioInputPlot.autoresizesSubviews = true
        audioInputPlot.addSubview(plot)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let backitem = UIBarButtonItem(title: Config.UI.PreNavItem, style: UIBarButtonItemStyle.Plain, target: self, action: "returnNavView")
        self.navigationItem.leftBarButtonItem = backitem
        
        let rightitem = UIBarButtonItem(title: "录音库 >", style: UIBarButtonItemStyle.Plain, target: self, action: "gotoNavView")
        self.navigationItem.rightBarButtonItem = rightitem
        
        AudioKit.output = silence
        setupPlot()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch let error as NSError {
            NSLog("Error: \(error)")
        }
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "stopRecording:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //NSNotificationCenter.defaultCenter().removeObserver(self)
        cleanup()
        
    }
    
    
    func returnNavView(){
        print("click return button")
        //self.navigationController?.popViewControllerAnimated(true)
        
        let mainViewController:MainViewController = MainViewController()
        let nvc=UINavigationController(rootViewController:mainViewController);
        self.slideMenuController()?.changeMainViewController(nvc, close: true)
        
    }
    
    func gotoNavView(){
        print("click goto button")
        //self.navigationController?.popViewControllerAnimated(true)
        
        //let fileViewController:FileViewController = FileViewController()
        let fileViewController:AudioFileList = AudioFileList()
        let nvc=UINavigationController(rootViewController:fileViewController);
        self.slideMenuController()?.changeMainViewController(nvc, close: true)
        
    }
    
    func audioRecorderViewControllerDismissed(withFileURL fileURL: NSURL?) {
        // do something with fileURL
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //func dismiss(sender: AnyObject) {
    //    cleanup()
    //    self.audioRecorderViewControllerDismissed(withFileURL: nil)
    // }
    
    
    @IBAction func saveAudio(sender: AnyObject) {
        
        
        let txtTitle:UITextField = UITextField()
        txtTitle.placeholder = "标题"
        txtTitle.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 1.0, alpha: 1.0)
        txtTitle.textColor = UIColor.darkGrayColor()
        
        
        let txtDesc:UITextField = UITextField()
        txtDesc.placeholder = "摘要"
        txtDesc.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 1.0, alpha: 1.0)
        txtDesc.textColor = UIColor.darkGrayColor()
        
        
        let btnOK:PKButton = PKButton(title: "确认",
                                      action: { (messageLabel, items) -> Bool in
                                        print("确认 is clicked.")
                                        let tmptxtTitle: UITextField = items[0] as! UITextField //items index number
                                        let tmptxtDesc: UITextField = items[1] as! UITextField //items index number
                                        
                                        if (tmptxtTitle.text == "" || tmptxtDesc.text == ""){
                                            messageLabel?.text = "请填写标题与摘要."
                                            tmptxtTitle.backgroundColor = UIColor(red: 0.95, green: 0.8, blue: 0.8, alpha: 1.0)
                                            tmptxtDesc.backgroundColor = UIColor(red: 0.95, green: 0.8, blue: 0.8, alpha: 1.0)
                                            return false
                                        }
                                        NSNotificationCenter.defaultCenter().addObserver(self, selector: "HandleResult:", name: Config.NotifyTag.ConvertToMP3AndPublish, object: nil)
                                        self.covertToMP3(tmptxtTitle.text!,desc: tmptxtDesc.text!)
                                        return true
            },
                                      fontColor: UIColor(red: 0, green: 0.55, blue: 0.9, alpha: 1.0),
                                      backgroundColor: nil)
        
        PKNotification.alert(
            title: "保存",
            message: "保存并发布至公众号",
            items: [txtTitle, txtDesc, btnOK],
            cancelButtonTitle: "取消",
            tintColor: nil)
        
    }
    
    func covertToMP3(title:String, desc:String){
        print("coverttomp3")
        let text = "请稍候，正在发布中..."
        //self.showWaitOverlayWithText(text)
        SwiftOverlays.showBlockingWaitOverlayWithText(text)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            let path = DaiFileManager.document["/Audio_Tmp/" + self.audioTmpFileName].path
            let pathMp3 = DaiFileManager.document["/Audio/" + self.audioFileName].path
            
            AudioWrapper.audioPCMtoMP3(path, pathMp3)
            
            
            DaiFileManager.document["/Audio/"+self.audioFileName].setAttr("C_Title", value: title)
            DaiFileManager.document["/Audio/"+self.audioFileName].setAttr("C_Desc", value: desc)
            DaiFileManager.document["/Audio/"+self.audioFileName].setAttr("C_Duration", value: self.timeLabel.text!)
            //PKNotification.toast("保存至录音资源库成功")
            dispatch_async(dispatch_get_main_queue(), {
                
                //这里返回主线程，写需要主线程执行的代码
                //println("这里返回主线程，写需要主线程执行的代码  --  Dispatch")
                let result:Result = Result(status: "OK",message:"保存至录音资源库成功",userinfo:NSObject(),tag:Config.NotifyTag.ConvertToMP3AndPublish)
                NSNotificationCenter.defaultCenter().postNotificationName(Config.NotifyTag.ConvertToMP3AndPublish, object: result)
            })
        }
        
    }
    
    
    func HandleResult(notify:NSNotification)
    {
        let result:Result = notify.valueForKey("object") as! Result
        NSNotificationCenter.defaultCenter().removeObserver(self, name: notify.name, object: nil)
        
        if result.status == "Error" {
            print("-------post  error-------------")
            PKNotification.toast(result.message)
            // Remove everything
            //self.removeAllOverlays()
            
            // Don't forget to unblock!
            SwiftOverlays.removeAllBlockingOverlays()
        }else if result.status=="OK"{
            if result.tag == Config.NotifyTag.ConvertToMP3AndPublish {
                print(result.message)
                //PKNotification.toast(result.message)
                
                //接着直接上传录音至服务器
                let filePath = DaiFileManager.document["/Audio/"+self.audioFileName].path
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "HandleResult:", name: Config.RequestTag.PostUploadAudioFile, object: nil)
                NetworkEngine.sharedInstance.postUploadFile(Config.URL.PostUploadAudioFile, filePath: filePath, tag: Config.RequestTag.PostUploadAudioFile)
            }else if result.tag == Config.RequestTag.PostUploadAudioFile{
                DaiFileManager.document["/Audio/"+self.audioFileName].setAttr("C_URL", value: Config.URL.AudioBaseURL + Message.shared.postUserName + "_" + self.audioFileName)
                //PKNotification.toast(result.message)
                print(result.message)
                //上传成功的话 就获取weixin token
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "HandleResult:", name: Config.RequestTag.GetWeiXinToken, object: nil)
                NetworkEngine.sharedInstance.addRequestWithUrlString(Config.URL.GetWeiXinToken, tag: Config.RequestTag.GetWeiXinToken, useCache: false) 
                
            }else if result.tag == Config.RequestTag.GetWeiXinToken{
                print(result.message)
                //得到token成功  发送音频信息及URL
                
                /*
                 {
                 "title":"TITLE",         //标题 
                 "content ":"CONTENT",    //内容
                 "audiourl":"AUDIOURL",   //音频链接 
                 "authorid ":"AUTHORID"   //作者工号
                 }
                 */
                let title = DaiFileManager.document["/Audio/"+self.audioFileName].getAttr("C_Title")
                let content = DaiFileManager.document["/Audio/"+self.audioFileName].getAttr("C_Desc")
                let audiourl = DaiFileManager.document["/Audio/"+self.audioFileName].getAttr("C_URL")
                let authorid = Message.shared.EmployeeId!
                
                print(Message.shared.EmployeeId)
                //let json = "{\"title\":\"\(title)\",\"content\":\"\(content)\",\"audiourl\":\"\(audiourl)\",\"authorid\":\"\(authorid)\"}"
                let json = "{title:\"\(title)\",content:\"\(content)\",audiourl:\"\(audiourl)\",authorid:\"\(authorid)\"}"
                
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "HandleResult:", name: Config.RequestTag.PostAudioTopic, object: nil)
                //tk001hkieder25091
                
                print(Config.URL.PostAudioTopic+result.message)
                NetworkEngine.sharedInstance.postRequestWithUrlString(Config.URL.PostAudioTopic+result.message, postData:json,tag:Config.RequestTag.PostAudioTopic)
                
            }else if result.tag == Config.RequestTag.PostAudioTopic{
                //result.userinfo as! String
                if result.status == "OK" {
                    print("OK userinfo= \(result.userinfo as! String)")
                    DaiFileManager.document["/Audio/"+self.audioFileName].setAttr("C_ReportID", value: result.userinfo as! String)
                    //btnCopyReportURL.hidden = false
                }
                PKNotification.toast(result.message)
                // Remove everything
                //self.removeAllOverlays()
                // Don't forget to unblock!
                SwiftOverlays.removeAllBlockingOverlays()
                
            }

            
            
        }
    }
    
    
    func cleanup() {
        timeTimer?.invalidate()
        print("do clean up")
        if let recorder = recorder{
            print("do record cleanup")
            if recorder.recording {
                print("do recorder stop")
                recorder.stop()
                recorder.deleteRecording()
                print("do AudioKit stop")
                AudioKit.stop()
            }
        }
        
        if let player = player {
            player.stop()
            self.player = nil
        }
    }
    
    
    
    func refreshControls(sender: AnyObject) {
        print ("update controls\(btn_Record.state)")
        
        if (sender as! NSObject == btn_Record){
            if let recorder = recorder{
                //btn_Play.enabled = !recorder.recording
                if recorder.recording {
                    //点录音开始/完成按钮后 录音中状态
                    btn_pause.hidden = false
                    btn_pause.enabled = true
                    btn_pause.setTitle("录音暂停", forState: UIControlState.Normal)
                    btn_pause.backgroundColor = UIColor.orangeColor()
                    
                    btn_Record.enabled = true
                    btn_Record.setTitle("录音完成", forState: UIControlState.Normal)
                    btn_Record.backgroundColor = UIColor.redColor()
                    
                    btn_Play.hidden = true
                    btn_Play.enabled = false
                    btn_Play.setTitle("播  放", forState: UIControlState.Normal)
                    btn_Play.backgroundColor = UIColor.grayColor()
                }else{
                    //点录音开始/完成铵扭后 录音停止状态
                    btn_pause.hidden = true
                    /*
                     btn_pause.enabled = false
                     btn_pause.setTitle("暂停录音", forState: UIControlState.Normal)
                     btn_pause.backgroundColor = UIColor.orangeColor()
                     */
                    btn_Play.hidden = false
                    btn_Play.enabled = true
                    btn_Play.setTitle("播  放", forState: UIControlState.Normal)
                    btn_Play.backgroundColor = self.recordercolor
                    
                    btn_Record.enabled = true
                    btn_Record.setTitle("录音开始", forState: UIControlState.Normal)
                    btn_Record.backgroundColor = self.recordercolor
                    
                }
                
            }else{
                print("recorder is nil")
            }
        }else if (sender as! NSObject == btn_Play){
            
            if let player = player{
                
                if player.playing{
                    //按播放/停止按钮  播放中
                    btn_Play.setTitle("停  止", forState: UIControlState.Normal)
                    btn_Play.backgroundColor = UIColor.redColor()
                    
                    btn_Record.enabled = false
                    btn_Record.backgroundColor = UIColor.grayColor()
                    
                    btn_pause.hidden = true
                    /*
                     btn_pause.enabled = false
                     btn_pause.backgroundColor = UIColor.grayColor()
                     */
                }else{
                    //按播放/停止按钮后 播放停止
                    btn_Play.enabled = true
                    btn_Play.setTitle("播  放", forState: UIControlState.Normal)
                    btn_Play.backgroundColor = self.recordercolor
                    
                    ///保持原状态
                    btn_Record.enabled = true
                    btn_Record.backgroundColor = self.recordercolor
                    
                    //btn_pause.hidden = false //保持原状态
                    btn_pause.enabled = true
                    btn_pause.setTitle("录音继续", forState: UIControlState.Normal)
                    btn_pause.backgroundColor = UIColor.orangeColor()
                    
                }
            }else{
                
                print("player is nil")
            }
            
        }else if (sender as! NSObject == btn_pause){
            //按下 录音暂停/继续 按钮后  暂停状态
            if sender.currentTitle == "录音暂停" {
                btn_pause.hidden = false
                btn_pause.enabled = true
                btn_pause.setTitle("录音继续", forState: UIControlState.Normal)
                btn_pause.backgroundColor = UIColor.orangeColor()
                
                btn_Record.enabled = true
                btn_Record.setTitle("录音完成", forState: UIControlState.Normal)
                btn_Record.backgroundColor = UIColor.redColor()
                
                btn_Play.hidden = true
                btn_Play.enabled = false
                btn_Play.setTitle("播  放", forState: UIControlState.Normal)
                btn_Play.backgroundColor = UIColor.grayColor()
                
                
            }else if sender.currentTitle == "录音继续" {
                btn_pause.hidden = false
                btn_pause.enabled = true
                btn_pause.setTitle("录音暂停", forState: UIControlState.Normal)
                btn_pause.backgroundColor = UIColor.orangeColor()
                
                btn_Record.enabled = true
                btn_Record.setTitle("录音完成", forState: UIControlState.Normal)
                btn_Record.backgroundColor = UIColor.redColor()
                
                btn_Play.hidden = true
                btn_Play.enabled = false
                btn_Play.setTitle("播  放", forState: UIControlState.Normal)
                btn_Play.backgroundColor = UIColor.grayColor()
                
            }
        }
        
    }
    
    
    // MARK: Time Label
    
    func updateTimeLabel(timer: NSTimer) {
        var ti:NSInteger = 0
        if ((recorder?.recording) == true) {
            ti = NSInteger(recorder!.currentTime)
        }else if ((self.player?.playing) == true){
            ti = NSInteger(self.player!.currentTime)
        }
        //var ms = Int((interval % 1) * 1000)
        
        let sec = ti % 60
        let min = (ti / 60) % 60
        let hour = (ti / 3600)
        
        timeLabel.text = NSString(format: "%02d:%02d:%02d",hour, min, sec) as String
        
    }
    
    
    // MARK: Playback Delegate
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        //self.player = nil
        refreshControls(btn_Play)
    }
    
    @IBAction func act_Record(sender: AnyObject) {
        print("act_record \(sender.currentTitle)")
        timeTimer?.invalidate()
        //print("sender =\(sender.enabled)")
        
        if let recorder = recorder{
            if sender.currentTitle == "录音完成" {
                print("set stop")
                recorder.stop()
                AudioKit.stop()
                btn_Save.enabled = true
            }else if sender.currentTitle == "录音开始"{
                print("set recording")
                timeLabel.text = "00:00:00"
                timeTimer = NSTimer.scheduledTimerWithTimeInterval(0.0167, target: self, selector: "updateTimeLabel:", userInfo: nil, repeats: true)
                //recorder.deleteRecording()
                //recorder.prepareToRecord()
                recorder.record()
                AudioKit.start()
                btn_Save.enabled = false
            }
        }else{
            print(" no recorder object")
        }
        refreshControls(sender)
    }
    
    @IBAction func act_Pause(sender: AnyObject) {
        print(sender.currentTitle)
        if sender.currentTitle == "录音暂停" {
            print("pause at \(recorder!.currentTime)")
            self.timeinterval = recorder!.currentTime
            timeTimer?.invalidate()
            recorder?.pause()
            //recorder?.stop()
            AudioKit.stop()
            
        }else if sender.currentTitle == "录音继续"{
            print("re record at \(self.timeinterval)")
            //recorder?.recordAtTime(self.timeinterval!)
            timeTimer = NSTimer.scheduledTimerWithTimeInterval(0.0167, target: self, selector: "updateTimeLabel:", userInfo: nil, repeats: true)
            recorder?.record()
            AudioKit.start()
        }
        refreshControls(sender)
    }
    @IBAction func act_Play(sender: AnyObject) {
        //print(self.player)
        timeTimer?.invalidate()
        self.player = nil
        if self.player == nil{
            print(" create player object")
            do {
                try self.player = AVAudioPlayer(contentsOfURL: outputURL)
            }
            catch let error as NSError {
                print("player init error\(error)")
            }
            player?.delegate = self
        }
        
        if let player = self.player {
            print("\(sender.currentTitle) \(player.duration)")
            if sender.currentTitle == "播  放"{
                timeTimer = NSTimer.scheduledTimerWithTimeInterval(0.0167, target: self, selector: "updateTimeLabel:", userInfo: nil, repeats: true)
                player.play()
                
            }else if sender.currentTitle == "停  止"{
                player.stop()
                
            }
            refreshControls(sender)
            
        }else{
            print("player no object")
        }
        
    }
    
    
}