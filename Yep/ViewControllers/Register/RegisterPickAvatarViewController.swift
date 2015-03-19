//
//  RegisterPickAvatarViewController.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation

class RegisterPickAvatarViewController: UIViewController {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var cameraPreviewView: CameraPreviewView!

    @IBOutlet weak var openCameraButton: BorderButton!

    @IBOutlet weak var cameraRollButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var retakeButton: UIButton!

    var avatar = UIImage() {
        willSet {
            avatarImageView.image = newValue
        }
    }

    enum PickAvatarState {
        case Default
        case CameraOpen
        case Captured
    }

    var pickAvatarState: PickAvatarState = .Default {
        willSet {
            switch newValue {
            case .Default:
                openCameraButton.hidden = false

                cameraRollButton.hidden = true
                captureButton.hidden = true
                retakeButton.hidden = true

                cameraPreviewView.hidden = true
                avatarImageView.hidden = false

                avatarImageView.image = UIImage(named: "default_avatar")

            case .CameraOpen:
                openCameraButton.hidden = true

                cameraRollButton.hidden = false
                captureButton.hidden = false
                retakeButton.hidden = true

                cameraPreviewView.hidden = false
                avatarImageView.hidden = true

                captureButton.setImage(UIImage(named: "button_capture"), forState: .Normal)

            case .Captured:
                openCameraButton.hidden = true

                cameraRollButton.hidden = false
                captureButton.hidden = false
                retakeButton.hidden = false

                cameraPreviewView.hidden = true
                avatarImageView.hidden = false

                captureButton.setImage(UIImage(named: "button_capture_ok"), forState: .Normal)
            }
        }
    }

    lazy var sessionQueue = {
        return dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
        }()

    lazy var session: AVCaptureSession = {
        let _session = AVCaptureSession()
        _session.sessionPreset = AVCaptureSessionPreset640x480

        return _session
        }()

    let mediaType = AVMediaTypeVideo

    lazy var videoDeviceInput: AVCaptureDeviceInput = {
        var error: NSError? = nil
        let videoDevice = self.deviceWithMediaType(self.mediaType, preferringPosition: .Front)
        return AVCaptureDeviceInput(device: videoDevice!, error: &error)
        }()

    lazy var stillImageOutput: AVCaptureStillImageOutput = {
        let _stillImageOutput = AVCaptureStillImageOutput()
        _stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        return _stillImageOutput
        }()

    override func viewDidLoad() {
        super.viewDidLoad()

        pickAvatarState = .Default

        openCameraButton.setTitleColor(UIColor.yepTintColor(), forState: .Normal)
        cameraRollButton.tintColor = UIColor.yepTintColor()
        captureButton.tintColor = UIColor.yepTintColor()
        retakeButton.setTitleColor(UIColor.yepTintColor(), forState: .Normal)
    }

    // MARK: Helpers

    private func deviceWithMediaType(mediaType: String, preferringPosition position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devicesWithMediaType(mediaType)
        var captureDevice = devices.first as? AVCaptureDevice
        for device in devices as! [AVCaptureDevice] {
            if device.position == position {
                captureDevice = device
                break
            }
        }

        return captureDevice
    }

    // MARK: Actions

    @IBAction func tryOpenCamera(sender: UIButton) {

        AVCaptureDevice.requestAccessForMediaType(mediaType, completionHandler: { (granted) -> Void in
            if granted {
                self.openCamera()

            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    YepAlert.alertSorry(message: NSLocalizedString("Yep doesn't have permission to use Camera, please change privacy settings", comment: ""), inViewController: self)
                }
            }
        })
    }

    private func openCamera() {

        dispatch_async(dispatch_get_main_queue()) {
            self.pickAvatarState = .CameraOpen
        }

        dispatch_async(sessionQueue) {

            if self.session.canAddInput(self.videoDeviceInput) {
                self.session.addInput(self.videoDeviceInput)

                dispatch_async(dispatch_get_main_queue()) {

                    self.cameraPreviewView.session = self.session
                    let orientation = AVCaptureVideoOrientation(rawValue: UIInterfaceOrientation.Portrait.rawValue)!
                    (self.cameraPreviewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = orientation

                    self.session.startRunning()
                }
            }

            if self.session.canAddOutput(self.stillImageOutput){
                self.session.addOutput(self.stillImageOutput)
            }
        }
    }

    @IBAction func tryOpenCameraRoll(sender: UIButton) {
    }

    @IBAction func captureOrFinish(sender: UIButton) {
        if pickAvatarState == .Captured {

        } else {
            dispatch_async(sessionQueue) {
                self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(self.mediaType
                    ), completionHandler: { (imageDataSampleBuffer, error) -> Void in
                        if error == nil {
                            let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                            var image = UIImage(data: data)!

                            image = UIImage(CGImage: image.CGImage, scale: image.scale, orientation: .LeftMirrored)!

                            image = image.fixRotation().largestCenteredSquareImage()

                            dispatch_async(dispatch_get_main_queue()) {
                                self.avatar = image
                                self.pickAvatarState = .Captured
                            }
                        }
                })
            }
        }
    }

    @IBAction func retake(sender: UIButton) {
        pickAvatarState = .CameraOpen
    }

}