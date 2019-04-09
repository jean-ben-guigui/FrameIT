//
//  ViewController.swift
//  FrameIT
//
//  Created by Arthur Duver on 11/10/2018.
//  Copyright © 2018 Arthur Duver. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        configure()
    }

    @IBOutlet var mainView: UIView!
    
    @IBOutlet weak var creationFrame: UIView!

    @IBOutlet weak var CreationImageView: UIImageView!
    
    @IBOutlet weak var unicornView: UIImageView!
    
    @IBOutlet weak var startOverButton: UIButton!
    
    @IBOutlet weak var colorLabel: UILabel!
    
    @IBOutlet weak var colorsContainer: UIView!
    
    @IBOutlet weak var shareButton: UIButton!
    
    @objc func changeImage(_ sender: UITapGestureRecognizer) {
        displayImagePickingOptions()
    }
    
    @objc func rotateImage(_ sender: UIRotationGestureRecognizer) {
        if !isImagePlaceholder {
            CreationImageView.transform = CreationImageView.transform.rotated(by: sender.rotation)
            sender.rotation = 0
        }
    }
    
    @objc func scaleImageView(_ sender: UIPinchGestureRecognizer) {
        if !isImagePlaceholder {
            CreationImageView.transform = CreationImageView.transform.scaledBy(x: sender.scale, y: sender.scale)
            sender.scale = 1
        }
    }
    
    @objc func moveImageView(_ sender: UIPanGestureRecognizer) {
        if !isImagePlaceholder {
            let translation = sender.translation(in: CreationImageView.superview)
            
            if sender.state == .began {
                initialImageViewOffset = CreationImageView.frame.origin
            }
            let position = CGPoint(x: initialImageViewOffset.x + translation.x - CreationImageView.frame.origin.x, y: initialImageViewOffset.y + translation.y - CreationImageView.frame.origin.y)
            
            CreationImageView.transform = CreationImageView.transform.translatedBy(x: position.x, y: position.y)
        }
    }
    
    @IBAction func share(_ sender: Any) {
        if let index = colorSwatches.index(where: {$0.caption == creation.colorSwatch.caption}) {
            savedColorSwatchIndex = index
        }
        displaySharingOptions(sender)
    }
    
    func displaySharingOptions(_ sender: Any) {
        //prepare the items to share
        let note = "avron !"
        let image = composeCreationImage()
        let items = [note as Any, image as Any]
        
        //present the sharing window
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivity.ActivityType.postToFacebook]
        activityViewController.popoverPresentationController?.sourceView = sender as? UIView
        present(activityViewController, animated: true, completion: nil)
    }
    
    func composeCreationImage() -> UIImage{
        UIGraphicsBeginImageContextWithOptions(creationFrame.bounds.size, false, 0)
        creationFrame.drawHierarchy(in: creationFrame.bounds, afterScreenUpdates: true)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return screenshot
    }
    
    @IBAction func startOver(_ sender: Any) {
            let oldColorSwatch = self.creation.colorSwatch
            self.creation.reset(colorSwatch: self.colorSwatches[self.savedColorSwatchIndex])
            UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping:0.5, initialSpringVelocity: 0.5, options: [],
            animations: {
                self.CreationImageView.transform = .identity
            },
            completion: {(success) in
                self.animateImageChange()
                self.startOverButton.isEnabled = false
                if oldColorSwatch.caption != self.colorSwatches[self.savedColorSwatchIndex].caption {
                    self.animateColorApply()
                }
            })
    }
    
    @IBAction func applyColor(_ sender: UIButton) {
        if let index = colorsContainer.subviews.index(of: sender) {
            if creation.colorSwatch.caption != colorSwatches[index].caption {
                creation.colorSwatch = colorSwatches[index]
                animateColorApply()
            }
        }
    }
    
    var localImages = [UIImage].init()
    
    let defaults = UserDefaults.init()
    
    var colorSwatches = [ColorSwatch].init()
    
    var colorUserDefaultsKey = "ColorIndex"
    
    var savedColorSwatchIndex:Int {
        get {
            let colorSwatchIndex = defaults.value(forKey: colorUserDefaultsKey)
            if colorSwatchIndex == nil {
                defaults.set(0, forKey: colorUserDefaultsKey)
                return 0
            }
            else {
                return defaults.integer(forKey: colorUserDefaultsKey)
            }
        }
        set {
            if newValue >= 0 && newValue < colorSwatches.count {
                defaults.set(newValue, forKey: colorUserDefaultsKey)
            }
        }
    }
    
    var creation = Creation.init()
    
    var initialImageViewOffset = CGPoint()
    
    var isImagePlaceholder = true
    
    var isUnicornLeftSide = true
    
    //getter functions
    func collectLocalImageSet() {
        localImages.removeAll()
        let imagesName = ["Boats", "Car", "Crocodile", "Park", "TShirts"]
        
        for imageName in imagesName {
            if let image = UIImage.init(named: imageName) {
                localImages.append(image)
            }
        }
    }
    
    func displayCamera() {
        let sourceType = UIImagePickerController.SourceType.camera
        
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            
            let noPermissionMessage = "Looks like FrameIT don't have access to your camera:( Please use Setting app on your device to permit FrameIT accessing your camera"
            let noPermissionAlert = getNoPermissionAlert();
            
            switch status {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                    if granted {
                        self.presentImagePicker(sourceType: sourceType)
                    } else {
                        self.troubleAlert(message: noPermissionMessage, additionalAction: noPermissionAlert)
                    }
                })
            case .authorized:
                self.presentImagePicker(sourceType: sourceType)
            case .denied, .restricted:
                self.troubleAlert(message: noPermissionMessage, additionalAction: noPermissionAlert)
            }
        }
        else {
            troubleAlert(message: "Sincere apologies, it looks like we can't access your camera at this time", additionalAction: nil)
        }
    }
    
    func displayLibrary() {
        let sourceType = UIImagePickerController.SourceType.photoLibrary
        
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            
            let status = PHPhotoLibrary.authorizationStatus()
            let noPermissionMessage = "Looks like FrameIT don't have access to your photos:( Please use Setting app on your device to permit FrameIT accessing your library"
            let noPermissionAlert = getNoPermissionAlert();
            
            switch status {
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization({ (newStatus) in
                    if newStatus == .authorized {
                        self.presentImagePicker(sourceType: sourceType)
                    } else {
                        self.troubleAlert(message: noPermissionMessage, additionalAction: noPermissionAlert)
                    }
                })
            case .authorized:
                self.presentImagePicker(sourceType: sourceType)
            case .denied, .restricted:
                self.troubleAlert(message: noPermissionMessage, additionalAction: noPermissionAlert)
            }
        }
        else {
            troubleAlert(message: "Sincere apologies, it looks like we can't access your photo library at this time", additionalAction: nil)
        }
    }
    
    func presentImagePicker(sourceType: UIImagePickerController.SourceType){
        let imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        present(imagePicker, animated: true, completion: nil)
    }
    
    func troubleAlert(message: String?, additionalAction:UIAlertAction?) {
        let alertController = UIAlertController(title: "Oops...", message:message , preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "Got it", style: .cancel)
        alertController.addAction(OKAction)
        if let action = additionalAction {
            alertController.addAction(action)
        }
        present(alertController, animated: true)
    }
    
    func pickRandom() {
        processPicked(image: randomImage())
    }
    
    func displayImagePickingOptions() {
        let alertController = UIAlertController(title: "Choose image", message: nil, preferredStyle: .actionSheet)
        
        // create camera action
        let cameraAction = UIAlertAction(title: "Take photo", style: .default) { (action) in
            self.displayCamera()
        }
        
        // add camera action to alert controller
        alertController.addAction(cameraAction)
        
        // create library action
        let libraryAction = UIAlertAction(title: "Library pick", style: .default) { (action) in
            self.displayLibrary()
        }
        
        // add library action to alert controller
        alertController.addAction(libraryAction)
        
        // create random action
        let randomAction = UIAlertAction(title: "Random", style: .default) { (action) in
            self.pickRandom()
        }
        
        // add random action to alert controller
        alertController.addAction(randomAction)
        
        // create cancel action
        let canceclAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // add cancel action to alert controller
        alertController.addAction(canceclAction)
        
        present(alertController, animated: true) {
            // code to execute after the controller finished presenting
        }
    }
    
    //UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let newImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        processPicked(image: newImage)
    }
    
    //initialize function
    
    //common fonctions
    func processPicked(image: UIImage?) {
        if let newImage = image {
            creation.image = newImage
//            isImagePlaceholder = false
            startOverButton.isEnabled = true
            animateImageChange()
        }
    }
    
    func getNoPermissionAlert() -> UIAlertAction {
        return UIAlertAction(title: "Go to settings", style: .default) { (action) in
            let settingsUrl = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func collectColors() {
        colorSwatches = [
            ColorSwatch.init(caption: "Ocean", color: UIColor.init(red: 44/255, green: 151/255, blue: 222/255, alpha: 1)),
            ColorSwatch.init(caption: "Shamrock", color: UIColor.init(red: 28/255, green: 188/255, blue: 100/255, alpha: 1)),
            ColorSwatch.init(caption: "Candy", color: UIColor.init(red: 221/255, green: 51/255, blue: 27/255, alpha: 1)),
            ColorSwatch.init(caption: "Violet", color: UIColor.init(red: 136/255, green: 20/255, blue: 221/255, alpha: 1)),
            ColorSwatch.init(caption: "Sunshine", color: UIColor.init(red: 242/255, green: 197/255, blue: 0/255, alpha: 1))
        ]
        
        if colorSwatches.count == colorsContainer.subviews.count {
            for i in 0 ..< colorSwatches.count {
                colorsContainer.subviews[i].backgroundColor = colorSwatches[i].color
            }
        }
    }
    
    
    
    func configure() {
        collectLocalImageSet()
        
        collectColors()
        
        creation.colorSwatch = colorSwatches[savedColorSwatchIndex]
        
        CreationImageView.image = creation.image
        colorLabel.text = creation.colorSwatch.caption
        creationFrame.backgroundColor = creation.colorSwatch.color
        startOverButton.isEnabled = false
//        CreationImageView.isUserInteractionEnabled = false
        
        // create tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(changeImage(_:)))
        CreationImageView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.delegate = self;
        
        //create rotate gesture recognizer
        let rotateGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotateImage(_:)))
        CreationImageView.addGestureRecognizer(rotateGestureRecognizer)
        rotateGestureRecognizer.delegate = self
        
        //create scale gesture recognizer
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(scaleImageView(_:)))
        CreationImageView.addGestureRecognizer(pinchGestureRecognizer)
        pinchGestureRecognizer.delegate = self
        
        let moveGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(moveImageView(_:)))
        CreationImageView.addGestureRecognizer(moveGestureRecognizer)
        pinchGestureRecognizer.delegate = self
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        //if gesture out of image
        if gestureRecognizer.view != CreationImageView {
            return false
        }
        
        //if gesture is not composed of rotate and pinch
        if gestureRecognizer is UITapGestureRecognizer || otherGestureRecognizer is UITapGestureRecognizer
            || gestureRecognizer is UIPanGestureRecognizer || otherGestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        
        return true
    }
    
    func animateImageChange() {
        UIView.transition(with: self.CreationImageView, duration: 0.4, options: .transitionCrossDissolve, animations: {
            self.CreationImageView.image = self.creation.image
        }, completion: nil)
    }
    
    func animateColorApply() {
            UIView.transition(with: self.creationFrame, duration: 0.4, options: .curveEaseIn, animations: {
                self.creationFrame.backgroundColor = self.creation.colorSwatch.color
            }, completion: nil)
            UIView.transition(with: self.colorLabel, duration: 0.4, options: .transitionFlipFromBottom, animations: {
                self.colorLabel.text = self.creation.colorSwatch.caption
            }, completion: nil)
    }
    
    func randomImage() -> UIImage? {
        print("localImage count \(localImages.count)")
        let randomNumber = arc4random_uniform(UInt32(localImages.count)-1)
        let image = localImages[Int(randomNumber)]
        //on vérifie que le localImages n'est pas vide et qu'il ne contient pas uniquement la même photo que celle choisie actuellement
        if localImages.count > 0 && (localImages.count != 1 || CreationImageView.image != localImages[0]) {
            if image != CreationImageView.image {
                let yPosition = Int(arc4random_uniform(UInt32(600)))
                UIView.transition(with: unicornView, duration: 2.0, options: .curveEaseInOut, animations: {
                    if self.isUnicornLeftSide {
                        self.isUnicornLeftSide = false
                        let screenSize = UIScreen.main.bounds.size.width
                        self.unicornView.frame.origin = CGPoint(x: Int(screenSize), y: yPosition)
                    }
                    else {
                        self.isUnicornLeftSide = true
                        let unicornViewSize = self.unicornView.bounds.size.width
                        self.unicornView.frame.origin = CGPoint(x: -Int(unicornViewSize), y: yPosition)
                    }
                }, completion: nil)
                return image
            }
            else {
                return randomImage()
            }
        }
        else {
            return nil
        }
    }
}

