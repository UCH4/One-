//
//  PartidosDataService.swift
//  LoginSwift
//
//  Created by Joaquin Ucha Gallo on 12/12/2025.
//

import Foundation

struct FiltroPartidos {
    var soloCoincidentesConPosicion: String?
    var soloDisponibles: Bool
}

protocol PartidosDataService {
    // Usuario
    func obtenerDatosDeUsuario(uid: String) async throws -> Jugador
    
    // Solicitudes
    func obtenerSolicitudes(partidoId: String) async throws -> [Solicitud]
    func actualizarEstadoSolicitud(id: String, aceptarSolicitante: String?, aceptarSolicitado: String?) async throws
    
    // Partidos
    func obtenerPartidosDisponibles(filtro: FiltroPartidos) async throws -> [Partido]
    func crearPartido(_ partido: Partido) async throws
    func unirseAPartido(_ partido: Partido, uidSolicitado: String) async throws
}

