//
//  SoundViewController.swift
//  CondoriSoundBoard
//
//  Created by Michell Condori on 13/05/24.
//

import UIKit
import AVFoundation
import CoreData

class SoundViewController: UIViewController {

    @IBOutlet weak var grabarButton: UIButton!
    @IBOutlet weak var reproducirButton: UIButton!
    @IBOutlet weak var nombreTextField: UITextField!
    @IBOutlet weak var agregarButton: UIButton!
    @IBOutlet weak var lblduracion: UILabel!
    @IBOutlet weak var volumen: UISlider!
   
    
    
    var grabarAudio: AVAudioRecorder?
    var reproducirAudio: AVAudioPlayer?
    var audioURL: URL?
    var temporizador: Timer?
    var duracionGrabacion: TimeInterval = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configurarGrabacion()
        reproducirButton.isEnabled = false
        agregarButton.isEnabled = false
        
        volumen.minimumValue = 0.0
            volumen.maximumValue = 1.0
            volumen.value = Float(reproducirAudio?.volume ?? 0.5)  
            
            volumen.addTarget(self, action: #selector(volumenCambiado(_:)), for: .valueChanged)    }
    
    @IBAction func grabarTapped(_ sender: Any) {
        if grabarAudio!.isRecording {
            // Detener la grabación
            grabarAudio?.stop()
            temporizador?.invalidate()
            temporizador = nil
            grabarButton.setTitle("GRABAR", for: .normal)
            reproducirButton.isEnabled = true
            agregarButton.isEnabled = true
        } else {
            // Empezar a grabar
            grabarAudio?.record()
            grabarButton.setTitle("DETENER", for: .normal)
            reproducirButton.isEnabled = false
            temporizador = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(actualizarDuracion), userInfo: nil, repeats: true)
        }
    }
    
    @IBAction func reproducirTapped(_ sender: Any) {
        do {
            try reproducirAudio = AVAudioPlayer(contentsOf: audioURL!)
            reproducirAudio?.play()
            print("Reproduciendo")
        } catch {}
    }
    
    @IBAction func agregarTapped(_ sender: Any) {
        temporizador?.invalidate()
        temporizador = nil
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let grabacion = Grabacion(context: context)
        grabacion.nombre = nombreTextField.text
        grabacion.audio = NSData(contentsOf: audioURL!)! as Data
        grabacion.duracion = formattedTime(from: duracionGrabacion)
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        navigationController?.popViewController(animated: true)
    }
    @objc func volumenCambiado(_ sender: UISlider) {
        reproducirAudio?.volume = sender.value
    }
    
    
    func configurarGrabacion() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [])
            try session.overrideOutputAudioPort(.speaker)
            try session.setActive(true)
            
            let basePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let pathComponents = [basePath, "audio.m4a"]
            audioURL = URL(fileURLWithPath: pathComponents.joined(separator: "/"))
            
            print("*********************")
            print(audioURL!)
            print("*********************")
            
            var settings: [String: AnyObject] = [:]
            settings[AVFormatIDKey] = Int(kAudioFormatMPEG4AAC) as AnyObject?
            settings[AVSampleRateKey] = 44100.0 as AnyObject?
            settings[AVNumberOfChannelsKey] = 2 as AnyObject?
            
            grabarAudio = try AVAudioRecorder(url: audioURL!, settings: settings)
            grabarAudio?.prepareToRecord()
        } catch let error as NSError {
            print(error)
        }
    }
    
    @objc func actualizarDuracion() {
        duracionGrabacion += 1
        lblduracion.text = formattedTime(from: duracionGrabacion)
    }
    
    func formattedTime(from seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        let formattedString = formatter.string(from: seconds) ?? "00:00"
        return formattedString
    }
}
