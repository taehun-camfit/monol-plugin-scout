/**
 * Scout Components Index
 * 모든 Scout 컴포넌트 export
 */

export { ScoutStatsCard } from './stats-card.js';
export { ScoutPluginList } from './plugin-list.js';
export { ScoutActivityChart } from './activity-chart.js';
export { ScoutOverview } from './overview.js';
export { ScoutTeamList } from './team-list.js';
export { ScoutInsightCard } from './insight-card.js';

// 컴포넌트 레지스트리 등록
import { ComponentRegistry } from '/design-system/component-base.js';
import { ScoutStatsCard } from './stats-card.js';
import { ScoutPluginList } from './plugin-list.js';
import { ScoutActivityChart } from './activity-chart.js';
import { ScoutOverview } from './overview.js';
import { ScoutTeamList } from './team-list.js';
import { ScoutInsightCard } from './insight-card.js';

ComponentRegistry.register('scout-stats', ScoutStatsCard);
ComponentRegistry.register('scout-plugins', ScoutPluginList);
ComponentRegistry.register('scout-chart', ScoutActivityChart);
ComponentRegistry.register('scout-overview', ScoutOverview);
ComponentRegistry.register('scout-team-list', ScoutTeamList);
ComponentRegistry.register('scout-insight-card', ScoutInsightCard);
