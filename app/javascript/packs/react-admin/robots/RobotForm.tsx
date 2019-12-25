import * as React from 'react';
import {
  SimpleForm,
  TextField,
  ArrayInput,
  SimpleFormIterator,
} from 'react-admin';
import { CardHeader, Card } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import {
  StyledSelectInput as SelectInput,
  StyledTextInput as TextInput,
  StyledNumberInput as NumberInput,
} from '../partials';
import { formOptions } from '../helpers';

export const StrategySelect = props => (
  <SelectInput
    {...props}
    source='strategy'
    choices={formOptions('copy', 'orderback', 'fixedprice', 'microtrades')}
  />
);

export const StateSelect = props => (
  <SelectInput
    {...props}
    source='state'
    choices={formOptions('disabled', 'enabled')}
  />
);

const useCardStyle = makeStyles({
  card: {
    padding: '24px',
    alignItems: 'center',
    marginTop: '37px',
  }
});

const CandleSticks = props => (
  <ArrayInput {...props} source='candlesticks'>
    <SimpleFormIterator>
      <TextInput source='type' />
      <TextInput source='period' />
      <TextInput source='min_amount' />
      <TextInput source='max_amount' />
    </SimpleFormIterator>
  </ArrayInput>
);

const RobotForm = props => (
  <React.Fragment>
    {props.title &&  <CardHeader title={props.title} />}
      <Card className={useCardStyle(props).card}>
        <h2>General</h2>

        <SimpleForm {...props} margin='dense'>
          <TextInput source='account' />
          <TextInput source='market' />
        </SimpleForm>
      </Card>

      {/* <CandleSticks /> */}
      <Card className={useCardStyle(props).card}>
        <h2>Orderbook</h2>

        <SimpleForm {...props} margin='dense'>
          <TextInput source='account_source' />
          <NumberInput source='period' />
          <NumberInput source='spread' />
        </SimpleForm>
      </Card>

      <Card className={useCardStyle(props).card}>
        <h2>Candlestick</h2>

        <SimpleForm {...props} margin='dense'>
          <TextInput source='type' />
          <NumberInput source='period' />
          <NumberInput source='min_amount' />
        </SimpleForm>
      </Card>
  </React.Fragment>
);

export default RobotForm;
