import * as React from 'react';
import {
  Create,
  DateField,
  Edit,
  Filter,
  List,
  TextField,
} from 'react-admin';

import {
  StyledDatagrid as Datagrid,
  StyledTextInput as TextInput,
  StyledSelectInput as SelectInput,
} from '../partials';
import RobotForm, { StateSelect, StrategySelect } from './RobotForm';


const RobotFilter = props => (
  <Filter {...props}>
    <StateSelect source='state' />
    <StrategySelect source='strategy' />
  </Filter>
);

export const RobotList = props => (
  <List {...props} filters={<RobotFilter />}>
    <Datagrid rowClick='edit'>
      <TextField source='id' />
      <TextField source='name' />
      <TextField source='strategy' />
      <TextField source='params' />
      <TextField source='state' />
      <DateField source='created_at' />
      <DateField source='updated_at' />
    </Datagrid>
  </List>
);

export const RobotEdit = props => {
  return (
    <Edit {...props} component={props =>(<div {...props}></div>)}>
      <RobotForm />
    </Edit>
  );
};

export const RobotCreate = props => (
  <Create {...props} component={props =>(<div {...props}></div>)}>
    <RobotForm />
    {/* <SimpleForm>
      <TextInput source='name' />
      <StrategySelect />
      <StateSelect />
      <ArrayInput source='_params' >
        <SimpleFormIterator>
          <TextInput source='key' />
          <FormDataConsumer>
            {({ formData, scopedFormData, getSource, ...rest }) =>
              scopedFormData && scopedFormData.key ? (
                  <TextInput
                      source={`params.${scopedFormData.key}`}
                      {...rest}
                  />
              ) : null
            }
          </FormDataConsumer>
        </SimpleFormIterator>
      </ArrayInput>
    </SimpleForm> */}
  </Create>
);
