//
//  PosicionPickerManager.swift
//  LoginSwift
//
//  Created by Joaquin Ucha Gallo on 08/08/2025.
//

import Foundation
import UIKit

class PosicionPickerManager: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    let posiciones =   ["delantero","atacante","mediafield","defensa","portero"]
    var onPoscionSeleccionada: ((String) -> Void)?
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return posiciones.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return posiciones[row]
    }
    func     pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        onPoscionSeleccionada?(posiciones[row])
    }
    
}
