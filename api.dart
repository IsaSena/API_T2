import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

void main() async {
  final router = Router();

  // Lista de veículos em memória (simulando um banco de dados)
  final List<Map<String, dynamic>> vehicles = [
    {'id': '1', 'model': 'Fusca', 'brand': 'Volkswagen', 'year': 1976},
    {'id': '2', 'model': 'Civic', 'brand': 'Honda', 'year': 2020},
    {'id': '3', 'model': 'J3', 'brand': 'Jac', 'year': 2010},
    {'id': '4', 'model': 'F-Type', 'brand': 'Jaguar', 'year': 2022},
  ];

  // Rota GET
  router.get('/vehicles', (Request request) {
    return Response.ok(jsonEncode(vehicles), headers: _corsHeaders);
  });

  // Rota POST
  router.post('/vehicles', (Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> newVehicle = jsonDecode(body);

    // Atribui um novo ID automaticamente
    newVehicle['id'] = (int.parse(vehicles.last['id']) + 1).toString();
    vehicles.add(newVehicle);

    return Response.ok(jsonEncode(newVehicle), headers: _corsHeaders);
  });

  // Rota PUT
  router.put('/vehicles/<id>', (Request request, String id) async {
    final body = await request.readAsString();
    final Map<String, dynamic> updatedVehicle = jsonDecode(body);

    // Encontra o índice do veículo com o ID fornecido
    final index = vehicles.indexWhere((vehicle) => vehicle['id'] == id);

    if (index == -1) {
      return Response.notFound('Veículo não encontrado');
    }

    // Atualiza os dados do veículo
    vehicles[index] = {
      'id': id,
      'model': updatedVehicle['model'],
      'brand': updatedVehicle['brand'],
      'year': updatedVehicle['year'],
    };

    return Response.ok(jsonEncode(vehicles[index]), headers: _corsHeaders);
  });

  // Rota DELETE
  router.delete('/vehicles/<id>', (Request request, String id) {
    final index = vehicles.indexWhere((vehicle) => vehicle['id'] == id);

    if (index == -1) {
      return Response.notFound('Veículo não encontrado');
    }

    // Remove o veículo da lista
    final deletedVehicle = vehicles.removeAt(index);
    return Response.ok(jsonEncode(deletedVehicle), headers: _corsHeaders);
  });

  // Configuração do servidor
  final handler = const Pipeline()
      .addMiddleware(_corsMiddleware())
      .addHandler(router);

  final server = await serve(handler, '103.101.1.103', 8080);
  print('Servidor ouvindo em http://${server.address.host}:${server.port}');
}

// Configuração dos cabeçalhos CORS
Map<String, String> get _corsHeaders => {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
};

// Middleware para adicionar CORS a todas as respostas
Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}
