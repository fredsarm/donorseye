import React, { useEffect, useState } from 'react';
import { Table, ConfigProvider } from 'antd';
import ptBR from 'antd/lib/locale/pt_BR';
import enUS from 'antd/lib/locale/en_US';
import moment from 'moment';
import 'moment/locale/pt-br';
import 'moment/locale/en-gb';

const AccEntriesTable = () => {
  const [data, setData] = useState([]);
  const [child, setChild] = useState([]);
  const [columnsAndLabels, setcolumnsAndLabels] = useState({});
  const [language, setLanguage] = useState({});

  useEffect(() => {
    const fetchData = async () => {
      try {
        const pWh = encodeURIComponent(JSON.stringify([{"col":"acc_id","comparisonOperator":">","value":"0"}]));
        const language = 'pt_br';
        let userLocale = navigator.language || navigator.userLanguage;
        const res = await fetch(`http://localhost:3000/api/acc_entries?pWh=${pWh}&language=${language}&userLocale=${userLocale}`);
        const resJson = await res.json();
        setData(resJson.data);
        setChild(resJson.child);
        setLanguage(language);
        setcolumnsAndLabels(resJson.columnsAndLabels.reduce((acc, cur) => {
          acc[cur.col_name] = cur[language];
          return acc;
        }, {}));
      } catch(error) {
        console.log(error);
      }
    };
    fetchData();
  }, []);

  const getLocale = () => {
    switch(language) {
      case 'pt_br':
        moment.locale('pt-br');
        return ptBR;
      default:
        moment.locale('en-gb');
        return enUS;
    }
  };

  const columnsModel = {
    'entry_id': { 
      dataIndex: 'entry_id', 
      sorter: {
        compare: (a, b) => a.entry_id - b.entry_id,
        multiple: 0
      },
      align: 'right',
      show: false,
    },
    'parent_id': { 
      dataIndex: 'parent_id', 
      sorter: {
        compare: (a, b) => Number(a.parent_id) - Number(b.parent_id), 
        multiple:0
      }

      // show: false,
    },
    'trans_date': { 
      dataIndex: 'trans_date', 
      sorter: {
        compare: (a, b) => new Date(a.trans_date) - new Date(b.trans_date),
        multiple:0
      },
      render: (text, record) => new Date(text).toLocaleDateString(language.replace("_", "-")),
      align: 'center'
    },
    'occur_date': { 
      dataIndex: 'occur_date', 
      sorter: {
        compare: (a, b) => new Date(a.occur_date) - new Date(b.occur_date),
        multiple:0
      },
      render: (text, record) => new Date(text).toLocaleDateString(language.replace("_", "-")),
      align: 'center'
    },
    'acc_id': { 
      dataIndex: 'acc_id', 
      show: false,
    },
    'acc_name': { 
      dataIndex: 'acc_name', 
      sorter: {
        compare: (a, b) => a.acc_name.localeCompare(b.acc_name), 
        multiple:0
      }
    },
    'memo': { 
      dataIndex: 'memo', 
      sorter: {
        compare: (a, b) => a.memo.localeCompare(b.memo),
        multiple:0
      }
    },
    'credit': { 
      dataIndex: 'credit', 
      sorter: {
        compare: (a, b) => Number(a.credit) - Number(b.credit),
        multiple:0,
      },
      render: (text, record) => Number(text).toLocaleString(language.replace("_", "-"), { minimumFractionDigits: 2 }),
      align: 'right'
    },
    'debit': { 
      dataIndex: 'debit', 
      sorter: {
        compare: (a, b) => Number(a.debit) - Number(b.debit),
        multiple:0
      },
      render: (text, record) => Number(text).toLocaleString(language.replace("_", "-"), { minimumFractionDigits: 2 }),
      align: 'right'
    },
    'entity_id': {
      dataIndex: 'entity_id',
      show: false,
    },
    'entity_name': {
      dataIndex: 'entity_name', 
      sorter: {
        compare: (a, b) => a.entity_name.localeCompare(b.entity_name),
        multiple:0
      }
    }
  };

  const nestedColumnsModel = {
    'parent_id': { 
      dataIndex: 'parent_id', 
      show: false, 
    },
    'acc_id': { 
      dataIndex: 'acc_id', 
      align: 'left',
      width: '60%',
      // show: false,

    },
    'acc_name': { 
      dataIndex: 'acc_name', 
      align: 'left',
      width: '60%',
    },
    'credit': { 
      dataIndex: 'credit', 
      render: (text, record) => Number(text).toLocaleString(language.replace("_", "-"), { minimumFractionDigits: 2 }),
      align: 'right',
      width: '20%',
      sorter: (a, b) => Number(a.credit) - Number(b.credit),
      defaultSortOrder: 'descend',
    },
    'debit': { 
      dataIndex: 'debit', 
      render: (text, record) => Number(text).toLocaleString(language.replace("_", "-"), { minimumFractionDigits: 2 }),
      align: 'right',
      width: '20%'
    },
  };

  const columnOrder = ['parent_id','trans_date', 'occur_date', 'memo','entity_name','acc_name', 'acc_id', 'entity_id', 'credit', 'debit'];
  const nestedColumnOrder = ['acc_name','credit', 'debit'];
console.log(data);
  if (Object.keys(columnsAndLabels).length === 0) {
    return null; // Ou algum componente de loading
  }

  const columns = columnOrder.map(key => ({
    ...columnsModel[key],
    title: columnsAndLabels[key]
  })).filter(column => column.show !== false);
  
  const nestedColumns = nestedColumnOrder.map(key => ({
    ...nestedColumnsModel[key],
    title: columnsAndLabels[key]
  })).filter(column => column.show !== false);

  return (
    <ConfigProvider locale={getLocale()}>
      <Table 
        columns={columns}
        dataSource={data} 
        rowKey='entry_id'
        pagination={{ 
          position: ['bottomCenter'],
          showSizeChanger: true,
          pageSizeOptions: ['10', '50', '100', '200']
        }}
        bordered
        size='small'   
        expandable={{
          expandedRowRender: record => {
            const nestedData = child.filter(item => item.parent_id === record.parent_id);
            return (
              <div style={{ 
                maxWidth: '50%',
                padding: '15px',
                backgroundColor: 'rgb(239, 239, 239)'
                }}>
                <Table
                  style={{ padding: '0px' }}
                  columns={nestedColumns}
                  dataSource={nestedData} 
                  rowKey='entry_id' 
                  pagination={false} 
                  size='small'   
                />
              </div>
            );
          },
          rowExpandable: record => data.some(item => item.parent_id === record.parent_id),
        }}
      />
    </ConfigProvider>
  );
};

export default AccEntriesTable;