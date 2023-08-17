import React, { useEffect, useState } from 'react';

import { Table, ConfigProvider, Input, Button, Space, DatePicker } from 'antd';
import ptBR from 'antd/lib/locale/pt_BR';
import enUS from 'antd/lib/locale/en_US';
import { SearchOutlined } from '@ant-design/icons';
import { RedoOutlined } from '@ant-design/icons';

import moment from 'moment';
import 'moment/locale/pt-br';
import 'moment/locale/en-gb';

const AccEntriesTable = () => {
  const [data, setData] = useState([]);
  const [child, setChild] = useState([]);
  const [columnsAndLabels, setcolumnsAndLabels] = useState({});
  const [userLocale, setUserLocale] = useState({});

  useEffect(() => {
    const fetchData = async () => {
      try {
        const pWh = encodeURIComponent(JSON.stringify([{"col":"acc_id","comparisonOperator":">","value":"0"}]));
        const navUserLocale = navigator.language || navigator.userLanguage;
        const headerColumnsLanguage = navUserLocale.replace("-", "_").toLowerCase();
        const res = await fetch(`http://localhost:3000/api/acc_entries?pWh=${pWh}&language=${headerColumnsLanguage}`);
        const result = await res.json();
        moment.locale(navUserLocale);
        setData(result.data);
        setChild(result.child);
        setUserLocale(navUserLocale);
        setcolumnsAndLabels(result.columnsAndLabels.reduce((acc, cur) => {
          acc[cur.col_name] = cur[headerColumnsLanguage];
          return acc;
        }, {}));
      } catch(error) {
        console.log(error); 
      }
    };
    fetchData();
  }, []);
// console.log(data);
  let antLocale = {}; // to be used with Ant Design Table
  switch(userLocale) {
    case 'pt-BR':
      antLocale=ptBR;
      break ;
    default:
      antLocale=enUS;
      break;
    }
  
    // to be used with the date exibition of the dropdown data filter
    const dateFormats = {
      'en-US': 'MM/DD/YYYY',
      'pt-BR': 'DD/MM/YYYY',
    };

  const columnsModel = {
    'entry_id': {
      dataIndex: 'entry_id',
      align: 'right',
      show: false,
    },
    'parent_id': {
      dataIndex: 'parent_id',
      filterType: 'number'    },
    'trans_date': {
      dataIndex: 'trans_date',
      filterType: 'date',
      render: (text, record) => new Date(text).toLocaleDateString(userLocale),
      align: 'center'
    },
    'occur_date': {
      dataIndex: 'occur_date',
      filterType: 'date',
      render: (text, record) => new Date(text).toLocaleDateString(userLocale),
      align: 'center'
    },
    'acc_id': {
      dataIndex: 'acc_id',
      show: false,
    },
    'acc_name': {
      dataIndex: 'acc_name',
      filterType: 'text'
    },
    'memo': {
      dataIndex: 'memo',
      filterType: 'text'
    },
    'credit': {
      dataIndex: 'credit',
      filterType:'number',
      render: (text, record) => Number(text) === 0 ? '' : Number(text).toLocaleString(userLocale, { minimumFractionDigits: 2 }),
      align: 'right'
    },
    'debit': {
      dataIndex: 'debit',
      filterType:'number',
      render: (text, record) => Number(text) === 0 ? '' : Number(text).toLocaleString(userLocale, { minimumFractionDigits: 2 }),
      align: 'right'
    },
    'entity_id': {
      dataIndex: 'entity_id',
      show: false,
    },
    'entity_name': {
      dataIndex: 'entity_name',
      filterType: 'text'
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
    },
    'path': {
      dataIndex: 'path',
      align: 'left',
      width: '60%',
    },
    'credit': {
      dataIndex: 'credit',
      render: (text, record) => Number(text) === 0 ? '' : columnsAndLabels['credit'].toLocaleString(userLocale) + ': ' + Number(text).toLocaleString(userLocale, { minimumFractionDigits: 2 }),
      align: 'right',
      width: '20%',
    },
    'debit': {
      dataIndex: 'debit',
      render: (text, record) => Number(text) === 0 ? '' : columnsAndLabels['debit'].toLocaleString(userLocale) + ': ' + Number(text).toLocaleString(userLocale, { minimumFractionDigits: 2 }),
      align: 'right',
      width: '20%'
    },
  };

  const columnsOrder = ['parent_id','trans_date', 'occur_date', 'memo','entity_name','acc_name', 'acc_id', 'entity_id', 'credit', 'debit'];
  const nestedcolumnsOrder = ['path','credit', 'debit'];

  const columns = columnsOrder.map(key => {
    let column = {
        ...columnsModel[key],
        title: columnsAndLabels[key]
    };

    switch (columnsModel[key].filterType) {
      case 'text':
            column = {
                ...column,
                filterDropdown: ({ setSelectedKeys, selectedKeys, confirm, clearFilters }) => (
                    <div style={{ padding: 8 }}>
                        <Input
                            placeholder={`${antLocale.Table.filterTitle} ${column.title}`}
                            value={selectedKeys[0]}
                            onChange={e => setSelectedKeys(e.target.value ? [e.target.value] : [])}
                            onPressEnter={() => confirm()}
                            style={{ width: 188, marginBottom: 8, display: 'block' }}
                        />
                        <Space>
                            <Button
                                type="primary"
                                onClick={() => confirm()}
                                icon={<SearchOutlined />}
                                size="small"
                                style={{ width: 90 }}
                            >
                            </Button>
                            <Button
                              onClick={() => {
                                clearFilters();
                                confirm();
                              }}
                              icon={<RedoOutlined />}
                              size="small"
                              style={{ width: 90 }}>
                            </Button>
                        </Space>
                    </div>
                ),
                filterIcon: filtered => <SearchOutlined style={{ color: filtered ? '#1890ff' : undefined }} />,
                onFilter: (value, record) => record[key].toString().toLowerCase().includes(value.toLowerCase()),
                sorter: {
                  compare: (a, b) => a[key].localeCompare(b[key]),
                  multiple:0
                }

            };
            break;
        case 'number':

          const parseNumberInput = (input, userLocale) => {
            let number = input;
          
            if (userLocale === 'pt-BR') {
              number = number.replace(/\./g, '').replace(',', '.');
            } else {
              number = number.replace(/,/g, '');
            }
          
            return parseFloat(number);
          };

            column = {
                ...column,
                filterDropdown: ({ setSelectedKeys, selectedKeys, confirm, clearFilters }) => (
                    <div style={{ padding: 8 }}>
                        <Input
                            placeholder={`${antLocale.Table.filterTitle} ${column.title}`}
                            value={selectedKeys[0]}
                            onChange={e => setSelectedKeys(e.target.value ? [e.target.value] : [])}
                            onPressEnter={() => confirm()}
                            style={{ width: 188, marginBottom: 8, display: 'block' }}
                        />
                        <Space>
                            <Button
                                type="primary"
                                onClick={() => confirm()}
                                icon={<SearchOutlined />}
                                size="small"
                                style={{ width: 90 }}
                            >
                            </Button>
                            <Button
                                onClick={() => {
                                  clearFilters();
                                  confirm();
                                }}
                                icon={<RedoOutlined />}
                                size="small"
                                style={{ width: 90 }}>
                            </Button>
                        </Space>
                    </div>
                ),
                filterIcon: filtered => <SearchOutlined style={{ color: filtered ? '#1890ff' : undefined }} />,
                onFilter: (value, record) => {
                  const parsedValue = parseNumberInput(value, userLocale);
                  return parseFloat(record[key]) === parsedValue;
                },
                sorter: {
                  compare: (a, b) => Number(a[key]) - Number(b[key]),
                  multiple:0,
                },
            };
            break;
        case 'date':
          column = {
            ...column,
            filterDropdown: ({ setSelectedKeys, selectedKeys, confirm, clearFilters }) => (
              <div style={{ padding: 8 }}>
                <DatePicker
                  placeholder={`${antLocale.Table.filterTitle} ${column.title}`}
                  // value={selectedKeys[0] ? moment(selectedKeys[0], 'YYYY-MM-DD') : null}
                  onChange={e => setSelectedKeys(e ? [e.format('YYYY-MM-DD')] : [])}
                  format={dateFormats[userLocale]}
                  onPressEnter={() => confirm()}
                  style={{ width: 188, marginBottom: 8, display: 'block' }}
                />
                <Space>
                  <Button
                    type="primary"
                    onClick={() => confirm()}
                    icon={<SearchOutlined />}
                    size="small"
                    style={{ width: 90 }}
                  >
                  </Button>
                  <Button
                    onClick={() => {
                      clearFilters();
                      confirm();
                    }}
                    icon={<RedoOutlined />}
                    size="small"
                    style={{ width: 90 }}>
                  </Button>
                </Space>
              </div>
            ),
            filterIcon: filtered => <SearchOutlined style={{ color: filtered ? '#1890ff' : undefined }} />,
            onFilter: (value, record) => {
              return moment(record[key]).format('YYYY-MM-DD') === value;
            },
            sorter: {
              compare: (a, b) => new Date(a[key]) - new Date(b[key]),
              multiple:0
            },
          };
          break;
        default:
            break;
    }

    return column;
  }).filter(column => column.show !== false);

  const nestedColumns = nestedcolumnsOrder.map(key => ({
    ...nestedColumnsModel[key],
    title: columnsAndLabels[key]
  })).filter(column => column.show !== false);

  return (
    <ConfigProvider locale={antLocale}>
      <Table
        columns={columns}
        dataSource={data}
        rowKey='entry_id'
        pagination={{
          position: ['topCenter'],
          showSizeChanger: true,
          // pageSize: 200,
          pageSizeOptions: ['200', '500' , '1000' , '2000']
        }}
        scroll={{ y: 800 }}
        bordered
        size='small'
        expandable={{
          expandedRowRender: record => {
            const nestedData = child.filter(item => item.parent_id === record.parent_id);
            return (
              <div style={{
                maxWidth: '50%',
                padding: '15px',
                margin: '0%',
                }}>
                <Table
                  id="accounting-entries"
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
