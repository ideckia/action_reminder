# Action for [ideckia](https://ideckia.github.io/): reminder

## Description

add quick reminders

## Properties

| Name | Type | Description | Shared | Default | Possible values |
| ----- |----- | ----- | ----- | ----- | ----- |
| sound_path | path | prop_sound_path | false | "ding.mp3" | null |

## On single click

TODO

## On long press

TODO

## Localizations

The localizations are stored in `loc` directory. A JSON for each locale.

## Test the action

There is a script called `test_action.js` to test the new action. Set the `props` variable in the script with the properties you want and run this command:

```
node test_action.js
```

## Example in layout file

```json
{
    "text": "reminder example",
    "bgColor": "00ff00",
    "actions": [
        {
            "name": "reminder",
            "props": {
                "sound_path": "ding.mp3"
            }
        }
    ]
}
```
