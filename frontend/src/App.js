// Importando React e os hooks 'useEffect' e 'useState' do pacote react
import React, { useEffect, useState } from 'react';
import './App.css';

// Importando o axios
import axios from 'axios';

// Definição do componente funcional 'App'
function App() {
  // Definição do estado 'data' e da função 'setData' para alterar este estado. O estado inicial é um array vazio.
  const [data, setData] = useState([]);

  // Definição do estado 'columns' e da função 'setColumns' para alterar este estado. O estado inicial também é um array vazio.
  const [columns, setColumns] = useState([]);

  // Definição do hook 'useEffect'. Esse hook é executado uma vez após o primeiro render do componente, pois o segundo argumento é um array vazio.
  useEffect(() => {
    // Chamada da API '/api/accEveEntries' com o método axios.get. O parâmetro '?select[]=*' indica que queremos selecionar todos os campos disponíveis.
    axios.get('/api/accEveEntries?select[]=*&where[0][column]=entry_id&where[0][operator]=%3C&where[0][value]=500')
      // Manipulação dos dados recebidos.
      .then(response => {
        // Definição do estado 'data' para os dados recebidos.
        setData(response.data);
        // Se houver dados, a primeira posição do array é usada para obter as chaves do objeto, que são definidas como colunas.
        if (response.data.length > 0) {
          setColumns(Object.keys(response.data[0]));
        }
      });
  }, []);

  // Renderização do componente
  return (
    <div className="App">
      <table>
        <thead>
          <h1>Cabeçalho da Tabela</h1>
        </thead>
        <tbody>


          <tr>
            {/* Mapeamento de cada coluna para uma célula de cabeçalho (<th>) */}
            {columns.map((column, index) => (
              <th key={index}>
                {column}
              </th>
            ))}
          </tr>


          {/* Mapeamento de cada objeto de dados para uma linha de tabela (<tr>) */}
          {data.map((row, index) => (


          <tr key={index}>
            {/* Mapeamento de cada coluna para uma célula de tabela (<td>) */}
            {columns.map((column, index) => (
              <td key={index}>
                {row[column]}
              </td>
            ))}
          </tr>



          ))}
        </tbody>
        <tfoot>
          <h1>Barra de Navegação</h1>
        </tfoot>
      </table>
    </div>
  );
}

// Exportação do componente App como padrão
export default App;
