import React from "react";
import { WorldIDWidget } from "@worldcoin/id";
const widgetProps = {
  actionId: "wid_staging_84f50bc0793fd815faae952ee96ebc9b",
  signal: "0x0Db723d5863A9B33AD83aA349B27F8136b6d5360",
  enableTelemetry: true,
  appName: "DAOCare",
  signalDescription: "Deployment address",
  theme: "light",
  debug: true,
  onSuccess: (result) => console.log(result),
  onError: ({ code, detail }) => console.log({ code, detail }),
  onInitSuccess: () => console.log("Init successful"),
  onInitError: (error) =>
    console.log("Error while initialization World ID", error),
};
function ActiveProposals() {
  return (
    <div>
      ActiveProposals
      <WorldIDWidget {...widgetProps} />
    </div>
  );
}

export default ActiveProposals;
