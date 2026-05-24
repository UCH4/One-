import Foundation
import UIKit

// MARK: - PosicionPickerManager
class PosicionPickerManager: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // 1. BASE PROVISIONAL (Los datos del Picker)
    // En el futuro, este array podría ser cargado desde una base de datos (Firestore).
    let posiciones = ["delantero", "atacante", "mediafield", "defensa", "portero"]
    
    // 2. EL CANAL DE COMUNICACIÓN (Closure)
    // Define una 'tubería' para enviar la posición seleccionada (String) a quien se suscriba.
    var onPoscionSeleccionada: ((String) -> Void)?
    
    // Propiedad para obtener la posición inicial por defecto
    var posicionActual: String {
        return posiciones.first ?? ""
    }
    
    // MARK: - UIPickerViewDataSource (¿Cuántas filas y componentes hay?)
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // Un solo componente (columna)
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return posiciones.count // El número de posiciones en el array
    }
    
    // MARK: - UIPickerViewDelegate (¿Qué mostrar y qué hacer al seleccionar?)
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        // Muestra el texto para cada fila
        return posiciones[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // 3. LA NOTIFICACIÓN: Cuando el usuario selecciona, llama al closure
        // y le pasa el dato seleccionado (String).
        onPoscionSeleccionada?(posiciones[row])
    }
}
