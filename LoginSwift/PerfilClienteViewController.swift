import FirebaseFirestore
import FirebaseAuth
import Foundation
import UIKit

class PerfilClienteViewController: UIViewController,UITextFieldDelegate {
    
    
    
    @IBOutlet weak var mailtxtfield: UITextField!
    @IBOutlet weak var maillbl: UILabel!
    @IBOutlet weak var apellidotxtfield: UITextField!
    @IBOutlet weak var nombrelbl: UILabel!
    @IBOutlet weak var apellidolbl: UILabel!
    @IBOutlet weak var posicionlbl: UILabel!
    @IBOutlet weak var posicionPickerView: UIPickerView!
    @IBOutlet weak var guardarbutton: UIButton!
    @IBOutlet weak var nombreTextField: UITextField!
 //   @IBOutlet weak var pickerView: UIPickerView!
   // let pickerManager = PosicionPickerManager()
    //private let db = Firestore.firestore()
    
    //private var  currenteUser: User?{
    //  return Auth.auth().currentUser
    //}
    let posiciones = ["delantero", "atacante", "mediafield", "defensor", "portero"]
    var uid :String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("RecordViewController viewDidLoad se ha llamado")
        ()
        
        //pickerView.delegate = pickerManager
        //pickerView.dataSource = pickerManager
       // pickerManager.onPoscionSeleccionada = { [weak self] posicion in
     //       self?.posicionlbl.text = posicion
   //     }
        
        posicionPickerView.delegate = self
        posicionPickerView.dataSource = self
        // Cualquier configuración inicial
        
        // Asigna el delegado de los UITextField a este ViewController
        mailtxtfield.keyboardType = .emailAddress
        nombreTextField.delegate = self
        apellidotxtfield.delegate = self
        mailtxtfield.delegate = self
        if let user = Auth.auth().currentUser{
            self.uid = user.uid
            cargarDatosUsuario(uid : user.uid)
        }
        
        
    }
    func cargarDatosUsuario(uid : String){
        let db = Firestore.firestore()
        db.collection( "Jugadores" ).document(uid).getDocument { document, error in
            if let error = error {
                print("Error al cargar datos :\(error.localizedDescription)")
            }
            if let document = document, document.exists {
                
                let data = document.data()
                self.nombreTextField .text = data?["nombre"] as? String ?? ""
                self.apellidotxtfield .text = data?["apellido"] as? String ?? ""
                let posicion = data?["posicion_preferente"] as? String ?? ""
                self.posicionlbl .text = posicion
                self.mailtxtfield .text = data?["email"] as? String ?? ""
                
                if let index = self.posiciones.firstIndex(of: posicion) {
                    self.posicionPickerView.selectRow(index, inComponent: 0, animated: false)
                }
                
                
            }
            
        }
    }
    @IBAction func savebutton(_ sender: UIButton) {
        guard let uid = self.uid else {return}
        print ("boton guardado")
        let nombre = nombreTextField.text ?? ""
        let apellido = self.apellidotxtfield.text ?? ""
        let mail = mailtxtfield.text ?? ""
        let posicion = posicionlbl.text ?? ""
        let db = Firestore.firestore()
        db.collection( "Jugadores" ).document(uid).updateData([
            "nombre": nombre,
            "apellido": apellido,
            "posicion_preferente": posicion,
            "email": mail
        ]) { error in
            if let error = error {
                print("Error al actualizar datos :\(error.localizedDescription)")
            } else {
                print("Datos actualizados correctamente")
                self.mostrarAlerta(titulo: "Exito", mensaje: "Datos actualizados correctamente")
            }
        }
    }
    func mostrarAlerta(titulo: String, mensaje: String) {
            let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alerta, animated: true, completion: nil)
        }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Cierra el teclado del textField actual
        return true
    }

}
    
       
 

extension PerfilClienteViewController : UIPickerViewDelegate, UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return posiciones.count
        
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return posiciones[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        posicionlbl.text = posiciones[row]
    }
}

