import React, { Component } from 'react'

import {
  TextInput,
  findNodeHandle,
  NativeModules,
  Platform
} from 'react-native'

const mask = NativeModules.RNTextInputMask.mask
const unmask = NativeModules.RNTextInputMask.unmask
const setMask = NativeModules.RNTextInputMask.setMask
const setText = NativeModules.RNTextInputMask.setText
export { mask, unmask, setMask }

export default class TextInputMask extends Component {
  static defaultProps = {
    maskDefaultValue: true,
    autoComplete: true,
    forceCapitals: false,
    autoCompleteOnFocus: true,
  }

  masked = false

  componentDidMount() {
    if (this.props.maskDefaultValue &&
        this.props.mask &&
        this.props.value) {
      mask(
        this.props.mask,
        '' + (this.props.forceCapitals ? this.props.value.toUpperCase() : this.props.value),
        this.props.autoComplete,
        text => this.input && this.input.setNativeProps({ text }),
      )
    }

    if (this.props.mask && !this.masked) {
      this.masked = true
      setMask(findNodeHandle(this.input), this.props.mask, this.props.forceCapitals, this.props.autoCompleteOnFocus)
    }
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.mask && (this.props.value !== nextProps.value)) {
      if (nextProps.value) {
        const lastValue = this.props.value;
        mask(
          this.props.mask,
          '' + (this.props.forceCapitals ? nextProps.value.toUpperCase() : nextProps.value),
          nextProps.autoComplete,
          (text) => {
            if (text !== lastValue) {
              this.input && this.input.setNativeProps({ text });
            }
          },
        );
      } else {
        this.input.setNativeProps({ text: nextProps.value })
      }
    }

    if (this.props.mask !== nextProps.mask || this.props.forceCapitals !== nextProps.forceCapitals) {
      setMask(findNodeHandle(this.input), nextProps.mask, nextProps.forceCapitals, nextProps.autoCompleteOnFocus)
    }
  }

  setText(text) {
    let textToSet = text || '';
    if (this.props.forceCapitals) {
      textToSet = textToSet.toUpperCase();
    }
    if (Platform.OS === 'ios') {
      setText(findNodeHandle(this.input), textToSet);
    } else {
      this.input.setNativeProps({ text: textToSet });
    }
  }

  render() {
    return (<TextInput
      {...this.props}
      value={undefined}
      ref={ref => {
        this.input = ref
        if (typeof this.props.refInput === 'function') {
          this.props.refInput(ref)
        }
      }}
      multiline={this.props.mask && Platform.OS === 'ios' ? false : this.props.multiline}
      onChangeText={masked => {
        if (this.props.mask) {
          const _unmasked = unmask(
            this.props.mask,
            masked,
            this.props.autoComplete,
            unmasked => {
              if (this.props.value !== masked) {
                this.props.onChangeText && this.props.onChangeText(masked, unmasked)
              }
            },
          )
        } else if (this.props.value !== masked) {
          this.props.onChangeText && this.props.onChangeText(masked)
        }
      }}
    />);
  }
}
