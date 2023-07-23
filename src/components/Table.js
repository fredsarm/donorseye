// components/Table.js

import React from 'react';

const Table = ({ entries }) => {
  // Assume that all entries have the same keys
  const columnNames = entries[0] && Object.keys(entries[0]);

  return (
    <table>
      <thead>
        <tr>
          {columnNames && columnNames.map(name => <th key={name}>{name}</th>)}
        </tr>
      </thead>
      <tbody>
        {entries.map((entry, index) => (
          <tr key={index}>
            {columnNames.map(name => <td key={`${index}-${name}`}>{entry[name]}</td>)}
          </tr>
        ))}
      </tbody>
    </table>
  );
};

export default Table; 
