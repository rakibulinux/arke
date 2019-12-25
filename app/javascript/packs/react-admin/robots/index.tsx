import * as React from 'react';
import {
  ArrayInput,
  Create,
  DateField,
  Edit,
  Filter,
  FormDataConsumer,
  List,
  SimpleForm,
  SimpleFormIterator,
  TextField,
  ListActions,
} from 'react-admin';

import {
  StyledDatagrid as Datagrid,
  StyledTextInput as TextInput,
  StyledSelectInput as SelectInput,
} from '../partials';
import RobotForm, { StateSelect, StrategySelect } from './RobotForm';


const RobotFilter = props => (
  <Filter {...props}>
    <SelectInput source='state' choices={[
      { id: 'disabled', name: 'disabled' },
      { id: 'enabled', name: 'enabled' },
    ]} />
    <SelectInput source='strategy' choices={[
      { id: 'copy', name: 'copy' },
      { id: 'orderback', name: 'orderback' },
      { id: 'fixedprice', name: 'fixedprice' },
      { id: 'microtrades', name: 'microtrades' },
    ]} />
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
    <Edit {...props} component={props =>(<div {...props}></div>)} >
      <RobotForm />
    </Edit>
  );
};

export const RobotCreate = props => (
  <Create {...props}>
    <SimpleForm>
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
    </SimpleForm>
  </Create>
);
